Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative 'amanda/post'
require_relative 'amanda/store'

require 'rack'
require 'camping'
require 'camping/session'
require 'dropbox_sdk'
require 'rdiscount'

Camping.goes :Amanda

STORE = Amanda::Store.new("amanda.yml")

module Amanda
  set :secret, "Some super secret, even more. No. MORE!"
  include Camping::Session
end

module Amanda::Controllers
  class Style < R '/s/(.+)'
    PATH = File.expand_path(File.dirname(__FILE__))
    def get(path)
      unless path.include? ".." # prevent directory traversal attacks
        serve "#{path}", File.read("#{PATH}/s/#{path}")
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end

  class Index < R '/'
    def get
      @last = STORE.last
      @random = STORE.random
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
    doctype!
    html do
      head do
       title { "AMANDA" }
       link rel: "stylesheet", type: "text/css", href: "/s/m.css"
      end
      body do
        div.container! do
          div.header! { render_header }
          self << yield
          div.footer! { render_footer }
        end
      end
    end
  end

  def render_header
  end

  def render_footer
  end

  def index
    div.post! class: "last" do
      h2 @last.title
      div.content! { RDiscount.new(@last.content, :smart).to_html }
      div.meta! @last.id
    end
    div.post! do
      h2 @random.title
      div.content! { RDiscount.new(@random.content, :smart).to_html }
      div.meta! @random.id
    end
  end

  def single
    div.post! do
      h2 @post.title
      div.content! { RDiscount.new(@post.content, :smart).to_html }
      div.meta! @post.id
    end
  end

  def archive
    ul class: "archive-list" do
      STORE.posts.map {|p| li {a(href: URL(p.to_param).to_s, title: p.title) { p.title }}}
    end
  end
end