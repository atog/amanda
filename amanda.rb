Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative 'amanda/post'
require_relative 'amanda/store'

require 'camping'
require 'rack'

Camping.goes :Amanda

STORE = Amanda::Store.new("amanda.yml")

module Amanda::Controllers
  class Index < R '/'
    def get
      render :index
    end
  end

  class Archive < R '/archive'
    def get
      render :archive
    end
  end
end

module Amanda::Views
  def layout
    html do
      head do
        title { "AMANDA" }
      end
      body { self << yield }
    end
  end

  def index
    STORE.redis.keys "*"
  end

  def archive
    ul do
      STORE.redis.keys("post:*").map {|p| li(Amanda::Post.from_json(STORE.redis.get(p)).title)}
    end
  end
end