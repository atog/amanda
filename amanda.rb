Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative 'amanda/helper'
require_relative 'amanda/post'
require_relative 'amanda/store'
require_relative 'amanda/feed'

require 'rack'
require 'camping'
require 'camping/session'
require 'dropbox_sdk'

Camping.goes :Amanda

module Amanda
  set :secret, "Some super secret, even more. No. MORE!"
  include Camping::Session

  $store = Amanda::Store.new("amanda.yml")
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
      @last = $store.last
      @random = $store.random
      while @random.id == @last.id
        @random =  $store.random
      end
      render :index
    end
  end

  class Post < R '/(\d{4})/(\d{2})/(\d{2})/(\d{4})(/?.*)?'
    def get(year, month, day, time, rest)
      @post = $store.post("#{year}#{month}#{day}#{time}")
      render :single
    end
  end

  class Tag < R '/tag/(.+)'
    def get(tag)
      @posts = $store.posts_for_tag(tag)
      render :multiple
    end
  end

  class Tags < R '/tags'
    def get
      @tags = $store.tags
      render :tags
    end
  end

  class Refresh < R '/refresh'
    def get
      $store.refresh_from_dropbox
      redirect "/"
    end
  end

  class Archive < R '/archive'
    def get
      render :archive
    end
  end

  class Feed < R '/feed'
    def get
      Amanda::Feed.rss $store.posts, title: "Koen Van der Auwera's blog", author: "Koen Van der Auwera", url: URL("/").to_s
    end
  end

  class Authorize < R '/authorize'
    def get
      session = DropboxSession.new(ENV["DROPBOX_APP_KEY"], ENV["DROPBOX_APP_SECRET"])
      session.get_request_token
      @state["dropbox"] = session
      redirect session.get_authorize_url(URL("/authorized").to_s)
    end
  end

  class Authorized < R '/authorized'
    def get
      if session = @state["dropbox"]
        session.get_access_token
        $store.dropbox_session(session)
        redirect "/refresh"
      else
        "TUUT"
      end
    end
  end

end

module Amanda::Views
  include Amanda::Helper

  def layout
    doctype!
    html do
      head do
       title { defined?(@post) && @post ? @post.title : "AMANDA" }
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

  def render_post(post)
    div.post! do
      h2 post.title
      div.content! { post.html }
      div.meta! post.id
    end
  end

  def index
    div.post! class: "last" do
      h2 @last.title
      div.content! { @last.html }
      div.meta! @last.id
    end
    div.post! do
      h2 @random.title
      div.content! { @random.html }
      div.meta! @random.id
    end
  end

  def single
    render_post(@post)
  end

  def multiple
    @posts.each do |post|
      render_post post
    end
  end

  def tags
    ul class: "tag-list" do
      @tags.map {|t| li {a(href: URL("tag/#{parameterize(t)}").to_s, title: t) { t }}}
    end
  end

  def archive
    ul class: "archive-list" do
      $store.posts.map {|p| li {a(href: URL(p.url).to_s, title: p.title) { p.title }}}
    end
  end
end