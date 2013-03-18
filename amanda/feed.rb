require "rss"
require "rss/rss"

module RSS
  module BaseModel
    def install_cdata_element(tag_name, uri, occurs, name=nil, type=nil, disp_name=nil)
      name ||= tag_name
      disp_name ||= name
      self::ELEMENTS << name
      add_need_initialize_variable(name)
      install_model(tag_name, uri, occurs, name)

      def_corresponded_attr_writer name, type, disp_name
      convert_attr_reader name
      install_element(name) do |n, elem_name|
        <<-EOC
        if @#{n}
          rv = "\#{indent}<#{elem_name}>"
          value = "<![CDATA[" + eval("@#{n}") + "]]>"
          if need_convert
            rv << convert(value)
          else
            rv << value
          end
          rv << "</#{elem_name}>"
          rv
        else
          ''
        end
EOC
      end
    end
  end

  class Rss
    class Channel
      class Item
        install_cdata_element "description", "", "?", "description"
      end
    end
  end
end

module Amanda
  class Feed

    def self.rss(posts, title: "title", url: "http://example.org", author: "John Doe")
      rss = RSS::Maker.make("2.0") do |maker|
        maker.channel.author = author
        maker.channel.updated = posts.first.published_at
        maker.channel.about = "#{url}/feed"
        maker.channel.title = title
        maker.channel.link = url
        maker.channel.description = title
        posts.each do |post|
          maker.items.new_item do |item|
            item.guid.content ="#{url.chomp("/")}#{post.url}"
            item.link = "#{url.chomp("/")}#{post.url}"
            item.title = post.title
            item.updated = post.published_at
            item.description = post.html
          end
        end
      end
      rss.to_s
    end

  end
end