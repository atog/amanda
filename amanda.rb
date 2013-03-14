Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative 'amanda/post'
require_relative 'amanda/store'

require 'rack'
require 'camping'
require 'camping/session'
require 'dropbox_sdk'

Camping.goes :Amanda

STORE = Amanda::Store.new("amanda.yml")

module Amanda
  set :secret, "Some super secret, even more. No. MORE!"
  include Camping::Session
end

module Amanda::Controllers
  class Index < R '/'
    def get
      render :index
    end
  end

  class Post < R '/(\d{4})/(\d{2})/(\d{2})/(\d{4})(/?.*)?'
    def get(year, month, day, time, rest)
      @post = STORE.post("#{year}#{month}#{day}#{time}")
      render :single
    end
  end

  class Refresh < R '/refresh'
    def get
      STORE.refresh_from_dropbox
      redirect "/"
    end
  end

  class Archive < R '/archive'
    def get
      render :archive
    end
  end

  class Authorize < R '/authorize'
    def get
      session = DropboxSession.new(STORE.dropbox_settings.fetch("app_key"), STORE.dropbox_settings.fetch("app_secret"))
      session.get_request_token
      @state["dropbox"] = session
      redirect session.get_authorize_url(URL("/authorized").to_s)
    end
  end

  class Authorized < R '/authorized'
    def get
      if session = @state["dropbox"]
        session.get_access_token
        STORE.dropbox_session(session)
        redirect "/"
      else
        "TUUT"
      end
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
    STORE.keys "*"
  end

  def single
    @post.title
  end

  def archive
    ul do
      STORE.posts.map {|p| li {a(href: URL(p.to_param).to_s, title: p.title) { p.title }}}
    end
  end
end