class HomeController < ActionController::Base
  def beta
  end

  def index
  	redirect_to "http://signup.waved.io"
  end
end