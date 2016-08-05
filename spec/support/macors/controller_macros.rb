module ControllerMacros
  def login_user(scope, user)
    user.confirm!
    sign_in scope, user
  end
end