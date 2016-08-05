module Extract
  extend ActiveSupport::Concern

  # 将redis中存储的字符串转化为二进制字符串再提取出ID
  def binary_to_ids(key)
    return [] unless $redis.bitcount(key) > 0

    str = $redis.get(key)

    ids = []
    str.unpack("B*")[0].split('').each_with_index do |i, index|
      ids << index if i == '1'
    end

    ids
  end

  # 将ID数组通过转化为二进制字符串再转化为string的方式存入redis
  def ids_to_string(ids)
    # 将数组去掉为0的值，否则会出bug
    ids.delete_if(&:zero?)
    arr = ids.sort

    binarys = []
    arr.each_with_index do |id, i|
      next unless id > 0

      from = (i == 0) ? 0 : arr[i-1]+1
      to = id - 1

      binarys.fill('0', from..to)
      binarys << '1'
    end

    [binarys.join('')].pack("B*")
  end

end
