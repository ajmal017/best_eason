module V1
  class Emotions < Grape::API
    resource :emotions, desc: "表情相关" do

      add_desc "获取所有表情及其图片地址"
      get do
        data = Caishuo::Utils::Text::EMOTIONS_ALL.map do |k,v|
          result = {type: k}
          result[:emotions] = v.map{|n,m| { key: n, url: "#{Caishuo::Utils::Text::EMOTIONS_PATH}#{m}"}}
          result
        end

        present data
      end

    end
  end
end
