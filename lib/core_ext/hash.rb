class Hash
 
  # 将hash转变成一个module, 定义方法，名为hash的key，值为value
  def to_module
    hash = self
    Module.new do
      hash.each_pair do |key, value|
        define_method key do
          value
        end
      end
    end
  end
end
