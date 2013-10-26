class LoginController < ApplicationController

  def connect

  end

  def redirect
    url = "https://foursquare.com/oauth2/access_token?client_id=#{AppConfig.foursquare.client_id}&client_secret=#{AppConfig.foursquare.client_secret}&grant_type=authorization_code&redirect_uri=#{AppConfig.foursquare.redirect_url}&code=#{params[:code]}"
    response = HTTParty.get(url)
    session[:access_token] = JSON.parse(response.body)["access_token"]
    redirect_to "/foursquare"
  end
end


