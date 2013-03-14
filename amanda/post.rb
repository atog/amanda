require 'json'

module Amanda

  class Error < StandardError; end;

  class Post

    attr_accessor :id, :title, :published, :date, :tags, :content

    def initialize(id=nil)
      @id = id
    end

    def self.from_json(data)
      data = JSON.parse(data)
      post = Post.new
      %w(id title published date tags content).each do |attr|
        post.send("#{attr}=", data[attr])
      end
      post
    rescue
      raise Amanda::Error.new(data.inspect)
    end

    def to_param
      "/#{id.gsub(/(\d{4})(\d{2})(\d{2})(\d{4})/, "\\1/\\2/\\3/\\4")}/#{parameterize(title)}"
    end

    def to_json
      {id: id, title: title, published: published, date: date, tags: tags, content: content}.to_json
    end

    def tags_to_arr
      @tags.split(",").map(&:strip) if @tags
    end

    def self.id_from_filename(filename)
      File.basename(filename, ".md")
    end

    def self.parse(filename, contents="")
      post = Post.new(id_from_filename(filename))
      contents = contents.force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
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
      else
        false
      end
    end

    # http://stackoverflow.com/a/9420531
    def non_ascii_encoding_options
      @naeo ||= {
        :invalid           => :replace,  # Replace invalid byte sequences
        :undef             => :replace,  # Replace anything not defined in ASCII
        :replace           => '',        # Use a blank for those replacements
        :universal_newline => true       # Always break lines with \n
      }
    end

    def remove_non_ascii(str)
      str.encode Encoding.find('ASCII'), non_ascii_encoding_options
    end

    # https://github.com/rails/rails/blob/a4278766068ee89fc910e113ef93d82071757965/activesupport/lib/active_support/inflector/transliterate.rb#L81
    def parameterize(str, sep="-")
      parameterized_string = remove_non_ascii(str)
      # Turn unwanted chars into the separator
      parameterized_string.gsub!(/[^a-z0-9\-_]+/i, sep)
      unless sep.nil? || sep.empty?
        re_sep = Regexp.escape(sep)
        # No more than one of the separator in a row.
        parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
        # Remove leading/trailing separator.
        parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/i, '')
      end
      parameterized_string.downcase
    end
  end
end
