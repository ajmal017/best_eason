module Caishuo::Utils::TextFilter
  class Cleaner
    class << self

      def clean(text, replace_str = "*")
        filter_words(text).map do |word|
          text.gsub!(/#{word}/, replace_string(word, replace_str))
        end
        text
      end

      def clean?(text)
        filter_words(text).blank?
      end

      def check(text)
        filter_words(text)
      end

      private

      def filter_words(text)
        text.length.times.map do |i|
          filter_word(text, i)
        end.flatten.compact.uniq
      end

      def filter_word(str, offset = 0)
        words = []
        len = 0
        while  offset + len < str.length
          status = Dict.get(str[offset, (len + 1)])
          case status
          when 2 then
            len = len + 1
            words.push(str[offset, len])
          when 1 then
            len = len + 1
          when 3 then
            words.push(str[offset, len + 1])
            break
          else
            break
          end
        end
        words
      end

      def replace_string(word, replace_str)
        word.length.times.map{ replace_str }.join
      end

    end

  end
end