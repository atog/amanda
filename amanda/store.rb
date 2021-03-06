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
    rescue
      nil
    end

    def redis
      @redis ||= Redis.connect(:url => ENV[ENV["REDIS_SERVICE"]])
    end

    def keys(pattern="*")
      redis.keys(pattern)
    end

    def tags
      redis.smembers(TAGS_KEY).sort!
    end

    def posts_for_tag(tag)
      redis_tag_id = "#{TAG_KEY_PREFIX}#{tag}" unless redis_tag_id =~ /^#{TAG_KEY_PREFIX}/
      redis.zrange(redis_tag_id, 0, -1).map{|p| post(p)}
    end

    def post(redis_post_id)
      redis_post_id = "#{POST_KEY_PREFIX}#{redis_post_id}" unless redis_post_id =~ /^#{POST_KEY_PREFIX}/
      Post.from_json(redis.get(redis_post_id))
    end

    def posts(count=-1)
      redis.zrevrange(POSTS_KEY, 0, count).map{|p| post(p)}
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
      metadata_params = ['/', 25000, true, nil, nil, true]
      client = DropboxClient.new(dropbox_session, :app_folder)
      metadata = client.metadata(*metadata_params)["contents"].map{|f| [f["path"], f["rev"], f["is_deleted"] || false]}
      metadata.select{|f| f[0] =~ /\d{12}\.md$/}.each do |path|
        if path[2]
          delete_post_in_redis(Post.id_from_filename(path[0]), path[1])
        elsif changed?(Post.id_from_filename(path[0]), path[1])
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

    def post_key(post_id)
      "#{POST_KEY_PREFIX}#{post_id}"
    end

    def delete_post_in_redis(post_id, rev)
      redis.del post_key(post_id)
      redis.zrem POSTS_KEY, post_key(post_id)
      redis.srem POSTS_RANDOM, post_key(post_id)
      if redis.get(POSTS_LAST_KEY) == post_key(post_id)
        redis.set POSTS_LAST_KEY, redis.zrange(POSTS_KEY, -1, -1).first
      end
      redis.keys("#{TAG_KEY_PREFIX}*").each do |tag_key|
        redis.zrem tag_key, post_key(post_id)
      end
    end

    def store_posts_in_redis(rposts)
      if rposts.any?
        rposts.each do |post|
          redis.set post_key(post.id), post.to_json
          redis.zadd POSTS_KEY, post.id, post_key(post.id)
          redis.sadd POSTS_RANDOM, post_key(post.id)
          redis.set POSTS_LAST_KEY, post_key(post.id)
          post.tags_to_arr.each do |tag|
            redis.sadd TAGS_KEY, tag
            redis.zadd "#{TAG_KEY_PREFIX}#{parameterize(tag)}", post.id, post_key(post.id)
          end
        end
      end
    end

  end

end