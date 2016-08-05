class Page
  TYPE = %w[ topics articles announcements news ]

  def initialize(type, id)
    @type = type
    @id = id
  end

  def url
    "#{Setting.host}/mobile/pages/#{@type}/#{@id}"
  end

end
