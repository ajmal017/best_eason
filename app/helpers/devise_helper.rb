module DeviseHelper

  def devise_login_error_messages!
    flash.map{|name,  msg| (content_tag :div, msg.html_safe, :id => "flash_#{name}" if msg.is_a?(String))}.join().html_safe
  end

  def devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t("errors.messages.not_saved",
                      :count => resource.errors.count,
                      :resource => resource.class.model_name.human.downcase)

    html = <<-HTML
    <div id="error_explanation">
      <h2>#{sentence}</h2>
      <ul>#{messages}</ul>
    </div>
    HTML

    html.html_safe
  end

  def devise_feedback_span(resource, field)
    return "" if resource.errors.empty?
    if resource.errors[field].present?
      content_tag(:span, nil, class: 'glyphicon glyphicon-remove form-control-feedback').html_safe
    else
      content_tag(:span, nil, class: 'glyphicon glyphicon-ok form-control-feedback').html_safe
    end  
  end

  def devise_error_info(resource, field)
    if resource.errors[field].present?
      content_tag(:label, resource.errors[field].first, class: 'col-md-3 info-label color-error').html_safe
    end
  end

  def devise_group_class(resource, field)
    if resource.errors.present? && resource.errors[field].present?
      "has-error has-feedback"
    elsif resource.errors.present?
      "has-success has-feedback"
    end
  end
end
