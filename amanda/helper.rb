module Amanda
  module Helper

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