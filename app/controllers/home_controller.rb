class HomeController < ActionController::Base
  def beta
  	redirect_to "itms-services://?action=download-manifest&url=https://s3.amazonaws.com/Heard_inHouse/manifest.plist"
  end

  def index
  	redirect_to "http://beta.waved.io"
  end
end