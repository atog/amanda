Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'rack'
require 'camping'
require 'camping/session'
require 'dropbox_sdk'

require_relative 'amanda/helper'
require_relative 'amanda/post'
require_relative 'amanda/store'
require_relative 'amanda/feed'

Camping.goes :Amanda

module Amanda
  set :secret, ENV["SECRET"]
  include Camping::Session
  include Amanda::Helper
  $store = Amanda::Store.new
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
      if $store.dropbox_session
        @last = $store.last
        @random = $store.random
        while @random.id == @last.id
          @random =  $store.random
        end
        render :index
      else
        redirect "/authorize"
      end
    end
  end

  class Post < R '/(\d{4})/(\d{2})/(\d{2})/(\d{4})(/?.*)?'
    def get(year, month, day, time, rest)
      @post = $store.post("#{year}#{month}#{day}#{time}")
      @last = $store.last
      render :single
    end
  end

  class Tag < R '/tag/(.+)'
    def get(tag)
      @last = $store.last
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

  class Refresh < R ENV["REFRESH_PATH"]
    def get
      $store.refresh_from_dropbox
      redirect "/"
    end
  end

  class Archive < R '/archive'
    def get
      @posts = $store.posts
      render :archive
    end
  end

  class Feed < R '/feed'
    def get
      Amanda::Feed.rss $store.posts(9), title: ENV["TITLE"], author: ENV["AUTHOR"], url: URL("/").to_s
    end
  end

  class Authorize < R '/authorize'
    def get
      if $store.dropbox_session
        redirect "/"
      else
        session = DropboxSession.new(ENV["DROPBOX_APP_KEY"], ENV["DROPBOX_APP_SECRET"])
        session.get_request_token
        @state["dropbox"] = session
        redirect session.get_authorize_url(URL("/authorized").to_s)
      end
    end
  end

  class Authorized < R '/authorized'
    def get
      if session = @state["dropbox"]
        session.get_access_token
        $store.dropbox_session(session)
        redirect ENV["REFRESH_PATH"]
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
        meta charset: "utf-8"
        meta :"http-equiv" => "X-UA-Compatible", content: "IE=edge,chrome=1"
        meta name: "description", content: ENV["TITLE"]
        link rel: "alternate", type: "application/rss+xml", title: "RSS", href: URL("/feed").to_s
        title { defined?(@post) && @post ? @post.title : ENV["TITLE"] }
        link rel: "stylesheet", type: "text/css", href: "/s/m.css"
      end
      body do
        div.container! do
          div.header! { render_header }
          div.content! { self << yield }
          div.footer! { render_footer }
        end
        script src: ENV["HAVEAMINT"], type: "text/javascript" if ENV["HAVEAMINT"]
      end
    end
  end

  def render_header
    div.nav! do
      ul class: "nav-list" do
        li {a(href: URL("/").to_s, title: "Home") { "Home" }}
        li {a(href: URL("/archive").to_s, title: "Archive") { "Archive" }}
        li {a(href: URL("/tags").to_s, title: "Tags") { "Tags" }}
      end
    end
  end

  def render_footer
    p do
      "Powered by " +
      a(href: "https://github.com/atog/amanda", title: "Amanda"){ "Amanda" }
    end
    p do
      "&copy; #{ENV["AUTHOR"]}"
    end
  end

  def render_meta(post)
    formatted_published_at(post)
  end

  def formatted_published_at(post)
    post.id.gsub(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/, "Laten vallen op \\3/\\2/\\1 om \\4:\\5u")
  end

  def render_tags(tags)
    ul class: "tag-list" do
      tags.each {|t| li {a(href: URL("/tag/#{parameterize(t)}").to_s, title: t) { t }}}
    end
  end

  def render_post(post, desc=nil)
    div.post! do
      h2 do
        a(href: URL(post.url).to_s, title: post.title) { post.title }
        span(class: "desc") { desc } if desc
      end
      div.content! { post.html }
      div.meta! { render_meta(post) }
      div.tags! { render_tags(post.tags_to_arr) }
    end
  end

  def index
    div.post! class: "last" do
      h2 do
        a(href: URL(@last.url).to_s, title: @last.title) { @last.title }
        span(class: "desc") {"nieuw!"}
      end
      div.content! { @last.html }
      div.meta! { render_meta(@last) }
      div.tags! {render_tags(@last.tags_to_arr) }
    end
    hr
    render_post @random, "Random"
  end

  def single
    p {a(href: URL(@last.url).to_s, title: @last.title, class: "last") { "Laatste: #{@last.title}" }} unless @last.id == @post.id
    render_post(@post)
  end

  def multiple
    p {a(href: URL(@last.url).to_s, title: @last.title, class: "last") { "Laatste: #{@last.title}" }}
    count = @posts.length-1
    @posts.each_with_index do |post, i|
      render_post post
      hr if i < count
    end
  end

  def tags
    render_tags(@tags)
  end

  def archive
    ul class: "archive-list" do
      @posts.each {|p| li {a(href: URL(p.url).to_s, title: p.title) { "#{p.published_date} &rarr; #{p.title}" }}}
    end
  end
end