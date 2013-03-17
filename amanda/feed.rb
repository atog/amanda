require "rss"

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
            # item.guid ="#{url}/#{post.url}"
            item.link = "#{url}/#{post.url}"
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