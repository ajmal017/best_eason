require 'rails/generators/resource_helpers'
require_relative 'named_base'

module Admin
  module Generators
    class ViewsGenerator < NamedBase
      include Rails::Generators::ResourceHelpers
      
      argument :attributes, type: :array, default: []
      
      def create_root_folder
        empty_directory File.join("app/views/admin", controller_file_path)
      end

      def copy_view_files
        available_views.each do |view_name|
          template view_name, File.join("app/views/admin/", controller_file_path, view_name)
        end
      end
      
      private

      def available_views
        %w(index.html.erb edit.html.erb show.html.erb new.html.erb _form.html.erb)
      end
   end
  end
end
