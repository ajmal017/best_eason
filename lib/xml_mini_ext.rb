module ActiveSupport::XmlMini
  extend self

  def rename_key_with_tag_names(key, options = {})
    key = options[:tag_names][key.to_sym] if options[:tag_names] && options[:tag_names].key?(key.to_sym)
    rename_key_without_tag_names(key, options)
  end

  alias_method_chain :rename_key, :tag_names
end

module ActiveModel::Serializers::Xml
  class Serializer
    def add_associations_with_format(association, records, opts)
      if opts[:without_root]
        opts = refer_options(opts)
        if records.respond_to?(:to_ary)
          records.to_ary.each do |record|
            record.to_xml opts
          end
        else
          records.to_xml opts
        end
      else
        add_associations_without_format(association, records, opts)
      end
    end

    def refer_options(opts)
      merged_options = opts.merge(options.slice(:builder, :indent))
      merged_options[:skip_instruct] = true
      [:skip_types, :dasherize, :camelize].each do |key|
        merged_options[key] = options[key] if merged_options[key].nil? && !options[key].nil?
      end
      merged_options
    end

    alias_method_chain :add_associations, :format
  end
end
