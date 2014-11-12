class Api::V1::ApiController < ApplicationController
  include ApplicationHelper
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
    if !params[:app_version]
      render json: {result: { message_type: "Blocking alert", message_content: "The beta is over! Please delete it and download the latest version on the App Store.", redirect_url: APP_STORE_LINK } }, status: 200
    elsif is_below_threshold(params[:app_version],"1")
      if is_below_threshold(params[:app_version],"0.1.1.10")
        render json: {result: { message_type: "Blocking alert", message_content: "This version is obsolete. Please download the latest beta version.", redirect_url: BETA_LINK } }, status: 200 
      else
        render json: {result: { message: "Beta Ok"} }, status: 200
      end
    else 
      if is_below_threshold(params[:app_version],VERSION_THRESHOLD)
        render json: {result: { message_type: "Blocking alert", message_content: "The beta is over! Please delete it and download the latest version on the App Store.", redirect_url: APP_STORE_LINK } }, status: 200
      elsif is_below_threshold(params[:app_version], GROUP_VERSION)
        render json: {result: { message_type: "Informative alert", message_content: "Group chat is now available! You should update to the latest version on the App Store.", redirect_url: APP_STORE_LINK } }, status: 200
      else
        render json: {result: { message: "Prod Ok"} }, status: 200
      end
    end

    # message type : "Informative alert", "Blocking alert", "Beta request"
  end
end