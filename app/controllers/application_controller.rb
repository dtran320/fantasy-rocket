class Unauthorized < StandardError
end

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include UrlHelper
  include I18nHelper

  rescue_from Unauthorized do
    render text: "Unauthorized (403)", status: 403
  end

  rescue_from ActiveRecord::RecordNotFound do
    render text: "Not found (404)", status: 404
  end

private

  def current_user
    @current_user ||= if cookies[:auth_token]
      User.find_by_auth_token!(cookies[:auth_token])
    elsif session[:user_id]
      # Legacy
      # Cookies implemented 9/6/2013
      # Can remove session a few weeks later

      User.find(session[:user_id])
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
  helper_method :current_user

  def current_sport
    @sport ||= case request.subdomain.split(".").first
    when 'nba'
      :nba
    else
      :nfl
    end
  end
  helper_method :sport

  def login_user(user)
    cookies[:auth_token] = {
      :value => user.auth_token,
      :domain => request.domain.prepend("."),
      :expires => 20.years.from_now.utc,
    }
  end

  def logout
    cookies.delete(:auth_token, domain: request.domain.prepend("."))
  end
end
