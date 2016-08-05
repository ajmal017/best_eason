require "trie"

module Caishuo::Utils::TextFilter
  class Dict
    include Singleton
    attr_reader :trie
    
    def initialize
      @trie = ::Trie.new
      load_words
    end

    def self.get(str)
      Dict.instance.trie.get(str)
    end

    private

    def load_words
      File.readlines(sensitive_words_file).each do |line|
        add_word(line.strip)
      end
    rescue Errno::ENOENT
      raise "请配置data/sensitive_words.txt文件"
    end

    def sensitive_words_file
      "#{Rails.root}/data/sensitive_words.txt"
    end

    # 1：表示词语片段
    # 2：属于其他已添加词语的一部分
    # 3：通常状态
    def add_word(word)
      return false if word.blank?
      word.length.times do |i|
        next if i == 0
        @trie.add(word[0, i], 1) if @trie.get(word[0, i]).to_i < 1
      end
      status = @trie.get(word).to_i
      if status == 1
        @trie.add(word, 2)
      elsif !([2, 3].include?(status))
        @trie.add(word, 3)
      end
    end
  end
end