require 'yaml'
require 'json'
require 'redis'
require 'dropbox_sdk'

module Amanda

  class Store

    POST_KEY_PREFIX = "post:"
    POSTS_KEY = "posts"
    POSTS_LAST_KEY = "posts:last"
    POSTS_ALL_KEY = "posts:all"
    DROPBOX = "dropbox"

    attr_accessor :config_file

    def initialize(config_file) @config_file = config_file; end;

    def config
      @config ||= YAML.load_file(config_file)
    end

    def path
      @path ||= config.fetch("posts_path")
    end

    def dropbox_settings
      config.fetch("dropbox")
    end

    def dropbox_session(session=nil)
      if session
        redis.set(DROPBOX, session.serialize)
      end
      DropboxSession.deserialize(redis.get(DROPBOX))
    end

    def redis
      @redis ||= ::Redis.new(host: config.fetch("redis").fetch("host", "localhost"),
                             port: config.fetch("redis").fetch("port", 6379))
    end

    def keys(pattern="*")
      redis.keys(pattern)
    end

    def post(redis_post_id)
      Post.from_json(redis.get(redis_post_id))
    end

    def posts
      redis.lrange(POSTS_ALL_KEY, 0, -1).map{|p| post(p)}
    end

    def random
      post(redis.srandmember(POSTS_KEY, 1))
    end

    def last
      post(redis.get("posts:last"))
    end

    def read_posts_from_dropbox
      posts = []
      client = DropboxClient.new(dropbox_session, :app_folder)
      client.metadata('/')["contents"].map{|f| f["path"]}.select{|f| f =~ /\d{8}-\d{4}\.md$/}.each do |path|
        contents, meta = client.get_file_and_metadata(path)
        posts << Post.parse(path, contents)
      end
      posts
    end

    def refresh_from_dropbox
      store_posts_in_redis(read_posts_from_dropbox)
    end

    def refresh_from_disk
      store_posts_in_redis(read_posts_from_disk)
    end

    def read_posts_from_disk
      posts = []
      Dir.glob(File.join(path, "*")).each do |post_file|
        if post_file =~ /\d{8}-\d{4}\.md$/
          posts << Post.parse_from_file(post_file)
        end
      end
      posts
    end

    def store_posts_in_redis(rposts)
      if rposts.any?
        redis.del(POSTS_ALL_KEY)
        rposts.each do |post|
          redis.set "#{POST_KEY_PREFIX}#{post.id}", post.to_json
          redis.sadd POSTS_KEY, "#{POST_KEY_PREFIX}#{post.id}"
          redis.set POSTS_LAST_KEY, "#{POST_KEY_PREFIX}#{post.id}"
          redis.rpush POSTS_ALL_KEY, "#{POST_KEY_PREFIX}#{post.id}"
        end
      end
    end

  end

end