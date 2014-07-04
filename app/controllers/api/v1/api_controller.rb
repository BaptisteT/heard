class Api::V1::ApiController < ApplicationController
  	respond_to :json
  	skip_before_action :verify_authenticity_token
  	before_action :authenticate_user
    skip_before_action :authenticate_user, only: :report_crash

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
    end
end