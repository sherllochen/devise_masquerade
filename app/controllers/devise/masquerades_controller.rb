class Devise::MasqueradesController < DeviseController
  if respond_to?(:prepend_before_action)
    prepend_before_action :authenticate_scope!
  else
    prepend_before_filter :authenticate_scope!
  end

  if respond_to?(:before_action)
    before_action :save_masquerade_owner_session, :only => :show
  else
    before_filter :save_masquerade_owner_session, :only => :show
  end

  if respond_to?(:after_action)
    after_action :cleanup_masquerade_owner_session, :only => :back
  else
    after_filter :cleanup_masquerade_owner_session, :only => :back
  end

  def show
    self.resource = resource_class.to_adapter.find_first(:uuid => params[:id])

    redirect_to(new_user_session_path) and return unless self.resource

    self.resource.masquerade!
    request.env["devise.skip_trackable"] = "1"

    if Devise.masquerade_bypass_warden_callback
      if respond_to?(:bypass_sign_in)
        bypass_sign_in(self.resource)
      else
        sign_in(self.resource, :bypass => true)
      end
    else
      sign_in(self.resource)
    end

    if Devise.masquerade_routes_back && Rails::VERSION::MAJOR == 5
      redirect_back(fallback_location: "#{after_masquerade_param_for(self.resource)}?#{after_masquerade_param_for(resource)}")
    elsif Devise.masquerade_routes_back && request.env['HTTP_REFERER'].present?
      redirect_to :back
    else
      redirect_to("#{after_masquerade_path_for(self.resource)}?#{after_masquerade_param_for(resource)}")
    end
  end

  def back
    user_id = session[session_key]

    owner_user = if user_id.present?
                   resource_class.to_adapter.find_first(:id => user_id)
                 else
                   send(:"current_#{resource_name}")
                 end

    if Devise.masquerade_bypass_warden_callback
      if respond_to?(:bypass_sign_in)
        bypass_sign_in(owner_user)
      else
        sign_in(owner_user, :bypass => true)
      end
    else
      sign_in(owner_user)
    end
    request.env["devise.skip_trackable"] = nil

    if Devise.masquerade_routes_back && Rails::VERSION::MAJOR == 5
      # If using the masquerade_routes_back and Rails 5
      redirect_back(fallback_location: after_back_masquerade_path_for(owner_user))
    elsif Devise.masquerade_routes_back && request.env['HTTP_REFERER'].present?
      redirect_to :back
    else
      redirect_to after_back_masquerade_path_for(owner_user)
    end
  end

  private

  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", :force => true)
  end

  def after_masquerade_path_for(resource)
    "/"
  end

  def after_masquerade_param_for(resource)
    "#{Devise.masquerade_param}=#{resource.masquerade_key}"
  end

  def after_back_masquerade_path_for(resource)
    "/"
  end

  def save_masquerade_owner_session
    session[session_key] = send("current_#{resource_name}").id unless session.key? session_key
  end

  def cleanup_masquerade_owner_session
    session.delete(session_key)
  end

  def session_key
    "devise_masquerade_#{resource_name}".to_sym
  end
end

