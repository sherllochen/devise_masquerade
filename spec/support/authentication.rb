module Authentication
  def logged_in
    @user ||= create(:user)

    sign_in @user
  end

  def current_user(model_name = :user)
    controller.send(:"current_#{model_name}")
  end
end

