# module ActionController
#   module Redirecting
#     # 只覆写了string url
#     def _compute_redirect_to_location(request, options)
#       case options
#       # The scheme name consist of a letter followed by any combination of
#       # letters, digits, and the plus ("+"), period ("."), or hyphen ("-")
#       # characters; and is terminated by a colon (":").
#       # See http://tools.ietf.org/html/rfc3986#section-3.1
#       # The protocol relative scheme starts with a double slash "//".
#       when /\A([a-z][a-z\d\-+\.]*:|\/\/).*/i
#         path_with_origin_params(request, path)
#       when String
#         request.protocol + request.host_with_port + path_with_origin_params(request, options)
#       when :back
#         request.headers["Referer"] or raise RedirectBackError
#       when Proc
#         _compute_redirect_to_location request, options.call
#       else
#         url_for(options)
#       end.delete("\0\r\n")
#     end

#     def path_with_origin_params(request, path)
#       return path if _origin_param(request).blank?
#       join_symbol = path =~ /\?/ ? "&" : "?"
#       path + join_symbol + _origin_param(request)
#     rescue
#       path
#     end

#     def _origin_param(request)
#       request.params.except(:controller, :action).to_param
#     end
#   end
# end