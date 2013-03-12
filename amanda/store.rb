require 'yaml'
require 'json'
require 'redis'

module Amanda

  class Store

    attr_accessor :config_file

    def initialize(config_file) @config_file = config_file; end;

    def config
      @config ||= YAML.load_file(config_file)
    end

    def path
      @path ||= config.fetch("posts_path")
    end

    def redis
      @redis ||= ::Redis.new(host: config.fetch("redis").fetch("host", "localhost"),
                             port: config.fetch("redis").fetch("port", 6379))
    end

    def read_posts_from_disk
      posts = []
      Dir.glob(File.join(path, "*")).each do |post_file|
        if post_file =~ /\d{8}-\d{4}\.md$/
          posts << Amanda::Post.parse(post_file)
        end
      end
      posts
    end

    def store_posts_in_redis
      read_posts_from_disk.each do |post|
        redis.set "post:#{post.id}", post.to_json
        redis.sadd "posts", "post:#{post.id}"
        redis.set "posts:last", "post:#{post.id}"
      end
    end

  end

end