require 'rails/generators/resource_helpers'
require_relative 'named_base'

module Admin
  module Generators
    class ControllerGenerator < NamedBase
      include Rails::Generators::ResourceHelpers
      
      argument :attributes, type: :array, default: [], banner: "field:type field:type"

      class_option :orm, type: :string, required: true

      def create_controller_files
        template 'controller.rb', File.join('app/controllers/admin', "#{ file_name.pluralize }_controller.rb")
      end
    
    end
  end
end
