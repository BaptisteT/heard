class HomeController < ActionController::Base
  def beta
  end

  def index
  	redirect_to "http://beta.waved.io"
  end
end