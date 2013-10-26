require 'net/http/post/multipart'

class FoursquareController < ApplicationController
  def index
    @user = me
  end

  def upload
    file = File.open("temp", "wb")
    file.write params[:picture].read
    session[:path] = file.path
    image = EXIFR::JPEG.new(session[:path])
    @checkins = existing_checkins(image)
    if @checkins.empty?
      @venues = venues_around_image_location(image)
    end
  end

  def checkin
    image = EXIFR::JPEG.new(session[:path])
    checkin_id = params[:checkin_id]
    venue_id = params[:venue_id]
    if checkin_id
      client.add_photo(
        :photo     => UploadIO.new(session[:path], "image/jpeg"),
        :checkinId => checkin_id
      )
      success = "https://foursquare.com/#{me.id}/checkin/#{checkin_id}"
    else
      response = client.add_checkin(:venueId => venue_id)
      if params[:upload_picture] == 'yes'
        client.add_photo(
          :photo     => UploadIO.new(session[:path], "image/jpeg"),
          :checkinId => response.id
        )
      end
      if params[:comment].present?
        client.add_checkin_comment(response.id, {:text => params[:comment]})
      end
      success = "https://foursquare.com/#{me.id}/checkin/#{response.id}"
    end
    redirect_to success
  end

  private

  def me
    @me ||= client.user('self')
  end

  def client
    @client ||= Foursquare2::Client.new(:oauth_token => session[:access_token])
  end

  def existing_checkins(image)
    timeframe = AppConfig.foursquare.checkin_lookup_timeframe.hours
    after_timestamp = (image.date_time_original - timeframe).to_i
    before_timestamp = (image.date_time_original + timeframe).to_i
    client.user_checkins(:afterTimestamp => after_timestamp, :beforeTimestamp => before_timestamp).items
  end

  def venues_around_image_location(image)
    venues = client.search_venues(:ll => "#{image.gps_latitude.to_f},#{image.gps_longitude.to_f}", :radius => AppConfig.foursquare.venues.radius, :limit => AppConfig.foursquare.venues.limit)
    venues.first.last.first.items
  end

end
