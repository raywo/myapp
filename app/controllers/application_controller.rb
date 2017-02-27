class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  # Every logged in user should be redirected to their own subdomain
  before_action :redirect_to_subdomain


  private

  def after_sign_in_path_for(resource_or_scope)
    dashboard_index_url(subdomain: resource_or_scope.subdomain)
  end # after_sign_in_path_for


  def after_sign_out_path_for(resource_or_scope)
    root_url(subdomain: '')
  end # after_sign_out_path_for


  def redirect_to_subdomain
    return if self.is_a?(DeviseController)

    if current_user.present? && request.subdomain != current_user.subdomain
      subdomain = current_user.subdomain
      host = request.host_with_port.sub! "#{request.subdomain}", subdomain

      redirect_to "http://#{host}#{request.path}"
    end # if
  end # redirect_to_subdomain


  def redirect_to_app_url
    return if request.subdomain.present? && request.subdomain == 'app'

    url = app_url
    redirect_to url
  end # redirect_to_app_url


  def app_url
    subdomain = 'app'

    if request.subdomain.present?
      host = request.host_with_port.sub! "#{request.subdomain}.", ''
    else
      host = request.host_with_port
    end # if

    "http://#{subdomain}.#{host}#{request.path}"
  end # app_url
end # class
