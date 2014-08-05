class Api::V1::ApiController < ApplicationController
	respond_to :json
	skip_before_action :verify_authenticity_token
	before_action :authenticate_user
  skip_before_action :authenticate_user, only: [:report_crash, :obsolete_api]

	def authenticate_user
		@current_user = User.find_by(auth_token: params[:auth_token])

		unless current_user
			render json: { errors: { unauthorized: "Invalid authentication token" } }, :status => 401
		end
	end

	def current_user
		@current_user
	end

  def report_crash
    SystemMailer.crash_email(params[:data]).deliver
    render nothing: true
  end

  # app_version related message
  def obsolete_api
    
    if !params[:app_version] || is_below_threshold(params[:app_version],THRESHOLD)
      render json: {result: { message_type: "Blocking alert", message_content: "Please download the latest version at www.waved.io/beta.", redirect_url: "http://www.waved.io/beta" } }, status: 200 
    else
      render json: {result: { message: "Ok"} }, status: 200
    end
    # if params[:app_version] == "1.1"
    #   render json: {result: { message_type: "Informative alert", message_content: "Download the new version", redirect_url: "http://itunes.apple.com/app/id734887535?mt=8" } }, status: 200
    # elsif params[:app_version] == "1.2"
    #   render json: {result: { message_type: "Blocking alert", message_content: "blabla", redirect_url: "http://itunes.apple.com/app/id734887535?mt=8" } }, status: 200
    # else
    #   render json: {result: { message: "Ok"} }, status: 200
    # end
  end

  private
    def is_below_threshold(app_version,threshold)
      threshold_array = threshold.split(".").map { |s| s.to_i }
      version_array = app_version.split(".").map { |s| s.to_i }
      (0..version_array.count).each do |i|
        if threshold_array.count < i || threshold_array[i] < version_array[i]
          return NO
        else if threshold_array[i] > version_array[i]
          return YES
        end
      end
      if threshold_array.count > version_array.count
        return YES
      else
        return NO
      end
    end
end