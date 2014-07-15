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
    current_user.update_attributes(:app_version => params[:api_version])
    # render json: {result: { message: "Ok"} }, status: 200
    if params[:api_version] == "1.1"
      render json: {result: { message_type: "Informative alert", message_content: "Download the new version", redirect_url: "http://itunes.apple.com/app/id734887535?mt=8" } }, status: 200
    elsif params[:api_version] == "1.2"
      render json: {result: { message_type: "Blocking alert", message_content: "blabla", redirect_url: "http://itunes.apple.com/app/id734887535?mt=8" } }, status: 200
    else
      render json: {result: { message: "Ok"} }, status: 200
    end
  end
end