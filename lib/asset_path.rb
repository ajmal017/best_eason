module Sprockets
  module Rails
    module Helper
      def path_to_asset(source, options = {})
        source = source.to_s
        return "" unless source.present?
        return source if source =~ URI_REGEXP

        tail, source = source[/([\?#].+)$/], source.sub(/([\?#].+)$/, '')

        if extname = compute_asset_extname(source, options)
          source = "#{source}#{extname}"
        end

        if source[0] != ?/
          source = compute_asset_path(source, options)
        end

        relative_url_root = defined?(config.relative_url_root) && config.relative_url_root
        if relative_url_root
          source = File.join(relative_url_root, source) unless source.starts_with?("#{relative_url_root}/")
        end

        source = timestamp(source) if source.starts_with?(*%w{javascripts /javascripts stylesheets /stylesheets})

        if host = compute_asset_host(source, options)
          source = File.join(host, source)
        end

        "#{source}#{tail}"
      end

      def timestamp(path)
        file_path = File.join('public', *path.split('/'))
        if File.exists?(file_path)
          path<<"?#{File.stat(file_path).mtime.to_i}"
        else
          path
        end
      end
    end
  end
end