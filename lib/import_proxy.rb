class ImportProxy
  # activerecord-import的一个代理，使用前请确保了解其接口
  def self.import(model, *args)
    import_start_at = Time.now
    begin
      ret = model.to_s.constantize.import(*args)
    rescue Exception => e
      $importer_logger.error("导入出错: args: #{args}\n, message: #{e.message}\n, backtrace: #{e.backtrace.join("\n")}")
    else
      $importer_logger.info("导入成功: 耗时: #{Time.now - import_start_at}s, result: #{ret.inspect}")
    end
  end
end