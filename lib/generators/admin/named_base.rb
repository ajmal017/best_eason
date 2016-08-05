module Admin
  module Generators
    class NamedBase < ::Rails::Generators::NamedBase
      include ActionView::Helpers::TagHelper

      protected

      def model_human_name
        klass.model_name.human
      end

      def klass
        class_name.safe_constantize
      end

      def human_attribute_name(attr)
        klass.human_attribute_name(attr)
      end

      def attributes_names
        @attributes_names ||= attributes.each_with_object([]) do |a, names|
          names << a.column_name
          names << 'password_confirmation' if a.password_digest?
        end
      end

      def parse_attributes!
        self.attributes = available_attributes.map do |attr|
          Rails::Generators::GeneratedAttribute.parse(attr)
        end
      end

      def available_attributes
        klass.columns_hash.map { |column_name, column| [column_name, column.type].join(':') }
      end

      def default_columns
        %w(id created_at updated_at)
      end

      def required_tag(attr)
        required = klass.validators_on(attr).any? { |v| v.kind_of? ActiveModel::Validations::PresenceValidator }
        content_tag(:b, required ? '*' : '').html_safe
      end

    end
  end
end
