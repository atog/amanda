require 'json'
require 'rdiscount'

module Amanda

  class Error < StandardError; end;

  class Post
    include Helper

    attr_accessor :id, :title, :published, :date, :tags, :content, :slug

    def initialize(id=nil)
      @id = id
    end

    def self.from_json(data)
      data = JSON.parse(data)
      post = Post.new
      %w(id title published date tags content slug).each do |attr|
        post.send("#{attr}=", data[attr].encode('iso-8859-1', 'utf-8')) if data[attr]
      end
      post
    rescue
      raise Amanda::Error.new(data.inspect)
    end

    def published_at
      @published_at ||= Time.mktime(*(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/.match(id).captures))
    end

    def published_date
      id.gsub(/(\d{4})(\d{2})(\d{2})(\d{4})/, "\\1-\\2-\\3")
    end

    def html
      @html ||= RDiscount.new(content, :smart).to_html
    end

    def url
      "/#{id.gsub(/(\d{4})(\d{2})(\d{2})(\d{4})/, "\\1/\\2/\\3/\\4")}/#{slug || parameterize(title)}"
    end

    def to_json
      {id: id, title: title, published: published, date: date, tags: tags, content: content, slug: slug}.to_json
    end

    def tags_to_arr
      if @tags
        @tags.split(",").map(&:strip)
      else
        []
      end
    end

    def self.id_from_filename(filename)
      File.basename(filename, ".md")
    end

    def self.parse(filename, contents="")
      post = Post.new(id_from_filename(filename))
      contents = contents.force_encoding("iso-8859-1").encode("utf-8", replace: nil)
      contents.split("\n").each do |line|
        unless head = match_header(post, line)
          post.content << "\n#{line}" rescue post.content = line
        end
      end
      post
    end

    def self.parse_from_file(filename)
      post = Post.new(id_from_filename(filename))
      IO.readlines(filename).each do |line|
        line = line.force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
        unless head = match_header(post, line)
          post.content << line rescue post.content = line
        end
      end
      post
    rescue => e
      puts "Problem parsing #{filename}"
      raise e
    end

    def self.match_header(obj, value)
      case value
      when /^title:/i then obj.title = value[6..-1].strip; true
      when /^published:/i then obj.published = value[10..-1].strip; true
      when /^date:/i then obj.date = value[5..-1].strip; true
      when /^tags:/i then obj.tags = value[5..-1].strip; true
      when /^slug:/i then obj.slug = value[5..-1].strip; true
      else
        false
      end
    end

  end
end
