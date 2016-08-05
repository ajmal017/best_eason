# module CanCan
#   module ControllerAdditions
#     module ClassMethods
#       # 设置默认参数
#       def load_and_authorize_resource_with_param_method(*args)
#         method_name = controller_path.classify.underscore.gsub("/","_").concat("_params")
#         args << {param_method: method_name.to_sym} unless args.to_s =~ /param_method/
#         load_and_authorize_resource_without_param_method(*args)
#       end
#
#       alias_method_chain :load_and_authorize_resource, :param_method
#     end
#   end
# end

