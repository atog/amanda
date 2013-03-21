require 'yaml'
require 'json'
require 'redis'
require 'dropbox_sdk'

module Amanda

  class Store
    include Helper

    POST_KEY_PREFIX = "post:"
    POSTS_KEY = "posts"
    POST_REV_PREFIX = "rev:post:"
    POSTS_LAST_KEY = "posts:last"
    POSTS_RANDOM = "posts:random"
    DROPBOX = "dropbox"
    TAGS_KEY = "tags"
    TAG_KEY_PREFIX = "tag:"

    def dropbox_session(session=nil)
      if session
        redis.set(DROPBOX, session.serialize)
      end
      DropboxSession.deserialize(redis.get(DROPBOX))
    end

    def redis
      @redis ||= ::Redis.new(host: ENV["OPENREDIS_URL"])
    end

    def keys(pattern="*")
      redis.keys(pattern)
    end

    def tags
      redis.smembers TAGS_KEY
    end

    def posts_for_tag(tag)
      redis_tag_id = "#{TAG_KEY_PREFIX}#{tag}" unless redis_tag_id =~ /^#{TAG_KEY_PREFIX}/
      redis.zrange(redis_tag_id, 0, -1).map{|p| post(p)}
    end

    def post(redis_post_id)
      redis_post_id = "#{POST_KEY_PREFIX}#{redis_post_id}" unless redis_post_id =~ /^#{POST_KEY_PREFIX}/
      Post.from_json(redis.get(redis_post_id))
    end

    def posts
      redis.zrange(POSTS_KEY, 0, -1).map{|p| post(p)}
    end

    def random
      post(redis.srandmember(POSTS_RANDOM))
    end

    def last
      post(redis.get(POSTS_LAST_KEY))
    end

    def changed?(post_id, rev)
      if stored_rev = redis.get("#{POST_REV_PREFIX}#{post_id}")
        return stored_rev != rev
      else
        redis.set "#{POST_REV_PREFIX}#{post_id}", rev
        return true
      end
    end

    def read_posts_from_dropbox
      posts = []
      client = DropboxClient.new(dropbox_session, :app_folder)
      client.metadata('/')["contents"].map{|f| [f["path"], f["rev"]]}.select{|f| f[0] =~ /\d{12}\.md$/}.each do |path|
        if changed?(Post.id_from_filename(path[0]), path[1])
          contents, meta = client.get_file_and_metadata(path[0])
          posts << Post.parse(path[0], contents)
        end
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
      Dir.glob(File.join(ENV["PATH"], "*")).each do |post_file|
        if post_file =~ /\d{8}\d{4}\.md$/
          posts << Post.parse_from_file(post_file)
        end
      end
      posts
    end

    def store_posts_in_redis(rposts)
      if rposts.any?
        rposts.each do |post|
          redis.set "#{POST_KEY_PREFIX}#{post.id}", post.to_json
          redis.zadd POSTS_KEY, post.id, "#{POST_KEY_PREFIX}#{post.id}"
          redis.sadd POSTS_RANDOM, "#{POST_KEY_PREFIX}#{post.id}"
          redis.set POSTS_LAST_KEY, "#{POST_KEY_PREFIX}#{post.id}"
          post.tags_to_arr.each do |tag|
            redis.sadd TAGS_KEY, tag
            redis.zadd "#{TAG_KEY_PREFIX}#{parameterize(tag)}", post.id, "#{POST_KEY_PREFIX}#{post.id}"
          end
        end
      end
    end

  end

end