module Mongoid
  module Persistable

    # Defines behaviour for persistence operations that update existing
    # documents.
    #
    # @since 4.0.0
    module Updatable


      # 更新属性前进行处理以适合mongodb
      def update(attributes = {}, options = {})
        # attrs = attributes.dup.merge!(new_attributes) do |k, v|
        #   next if v.nil?
          
        #   # 转换时间格式
        #   next v.to_time if [ActiveSupport::TimeWithZone, Date, DateTime].include?(v.class)
          
        #   # 添加多态关联类名的Mongo后缀
        #   k =~ /(.+)_type$/ && attributes.has_key?(k.to_s.gsub(/_type$/, '_id')) && v[0..3] != 'MD::' ? "MD::#{v}" : v
        # end
        assign_attributes(attributes)
        save(validate: (options[:validate].nil? or options[:validate]))
      end

    end
  end




  # module Relations
  #   class Metadata
      # 关联的类名后自动加Mongo
    #   def class_name_with_mongo
    #     class_name_without_mongo[0..3] == 'MD::' ? class_name_without_mongo : "MD::#{class_name_without_mongo}"
    #   end
    #   alias_method_chain :class_name, :mongo
      
    #   # 关联的外键名后自动删Mongo
    #   def foreign_key_with_unmongo
    #     foreign_key_without_unmongo.sub(/^md_/, '')
    #   end
    #   alias_method_chain :foreign_key, :unmongo
      
    #   # belongs_to关联的默认class_name不进行单数化
    #   def classify_with_camelizebelongsto
    #     macro == :referenced_in ? name.to_s.camelize : classify_without_camelizebelongsto
    #   end
    #   alias_method_chain :classify, :camelizebelongsto
    # end
    
    # class Builders::Referenced::In
    #   # 建立belongs_to关联时自动加Mongo
    #   def build_with_mongo(type = nil)
    #     build_without_mongo(type.present? && type[0..3] != 'MD::' ? "MD::#{type}" : type)
    #   end
    #   alias_method_chain :build, :mongo
    # end
    
    # class Referenced::In
    #   class << self
    #     # 多态belongs_to的eager_load
    #     def eager_load_with_polymorphic(metadata, ids)
    #       if metadata.polymorphic?
    #         ids = ids.compact.uniq
    #         metadata.inverse_klass.any_in((fk = metadata.foreign_key) => ids).distinct(fk.gsub(/_id$/, '_type')).compact.each do |type|
    #           type.constantize.any_in("_id" => ids).each {|doc| IdentityMap.set(doc)}
    #         end
    #       else
    #         eager_load_without_polymorphic(metadata, ids)
    #       end
    #     end
    #     alias_method_chain :eager_load, :polymorphic
    #   end
    # end
  # end

end