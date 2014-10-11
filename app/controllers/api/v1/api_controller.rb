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
    if params[:app_version] and is_below_threshold(params[:app_version],"1")
      render json: {result: { message: "Beta Ok"} }, status: 200
    elsif !params[:app_version] || is_below_threshold(params[:app_version],VERSION_THRESHOLD)
      render json: {result: { message_type: "Blocking alert", message_content: "The beta is over! Please download the latest version on the App Store.", redirect_url: APP_STORE_LINK } }, status: 200 
    else
      # here select beta tester params[:user_id]
      render json: {result: { message: "Prod Ok"} }, status: 200
    end
    # message type : "Informative alert", "Blocking alert", "Beta request"
  end

  private
    def is_below_threshold(app_version,threshold)
      if !app_version
        return false
      end
      
      threshold_array = threshold.split(".").map { |s| s.to_i }
      version_array = app_version.split(".").map { |s| s.to_i }
      (1..version_array.count).each do |i|
        if threshold_array.count < i || threshold_array[i-1] < version_array[i-1]
          return false
        elsif threshold_array[i-1] > version_array[i-1]
          return true
        end
      end
      if threshold_array.count > version_array.count
        return true
      else
        return false
      end
    end
end