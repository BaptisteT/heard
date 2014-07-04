class SystemMailer < ActionMailer::Base

  default from: SENDER_EMAIL

  def crash_email(crash_data)
    @crash_data = crash_data
    mail(to: SENDER_EMAIL, subject: 'Crash report')
  end

end