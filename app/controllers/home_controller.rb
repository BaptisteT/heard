class HomeController < ApplicationController
  include ApplicationHelper

  def beta
  end

  def groups
  end

  def index
  end

  def text_link
    invited_number = InvitedNumber.new
    invited_number.phone_number = params[:number]
    
    if invited_number.save
      begin
        client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
        client.account.messages.create(
          from: TWILIO_PHONE_NUMBER,
          to:   params[:number],
          body: "Download Waved for iPhone at " + DOWNLOAD_LINK + "."
        )
        @result_message = "Thanks. We sent a download link to your phone."
      rescue Twilio::REST::RequestError => e
        Airbrake.notify(e)
        @result_message = "Sorry, an error occured."
      end
    end

    render :index
  end

  def privacy
  end

  def stats
    @lastDayCount = FutureMessage.where("created_at >=? and text_sent =?",1.week.ago.utc,true).count
    @lastWeekCount = FutureMessage.where("created_at >=? and text_sent =?",1.day.ago.utc, true).count
    @totalCount = FutureMessage.where(text_sent: true).count

    @lastDayRecipientCount = FutureMessage.where("created_at >=? and text_sent =?",1.week.ago.utc,true).select(:receiver_number).uniq.count
    @lastWeekRecipientCount = FutureMessage.where("created_at >=? and text_sent =?",1.day.ago.utc,true).select(:receiver_number).uniq.count
    @totalRecipientCount = FutureMessage.where(text_sent: true).select(:receiver_number).uniq.count
  end

  def user_stats
    period = 0.hours

    if (params[:m])
      period += params[:m].to_i.months
    end

    if (params[:d])
      period += params[:d].to_i.days
    end

    if (params[:h])
      period += params[:h].to_i.hours
    end

    if (period < 1.hour)
      period = 24.hours
      params[:h] = 24
    end

    id_counts = {}
    @sorted_users = []

    messages = Message.where("created_at >= :start_date", {start_date: Time.now - period})

    @message_count = messages.count

    messages.each {|m| id_counts[m.sender_id] = id_counts[m.sender_id] ? id_counts[m.sender_id] + 1 : 1}

    id_counts.each {|id, count| @sorted_users << [User.find(id), count]}

    @sorted_users = @sorted_users.sort_by {|e| -e[1]}
  end
end