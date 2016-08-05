module Helper

  def create_current_user!(options={})
    @current_user = FactoryGirl.create(:user, options) do |u|
      FactoryGirl.create(:api_token, user_id: u.id)
    end
  end

  def current_user
    @current_user
  end

  def status
    result = JSON.parse(@response.body)
    result["status"]
  end

  def error_code
    result = JSON.parse(@response.body)
    result["error"].try(:fetch, "code")
  end

  def error_msg
    result = JSON.parse(@response.body)
    result["error"].try(:fetch, "msg")
  end

  def data
    result = JSON.parse(@response.body)
    result["data"]
  end

  def ext
    result = JSON.parse(@response.body)
    result["ext"]
  end

  def success!
    status.should == 1
  end

  def failed!
    status.should == 0
  end
end
World(Helper)
World(Rack::Test::Methods)
