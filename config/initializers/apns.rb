APNS::Notification.class_eval do 
  def packaged_message
      aps = {'aps'=> {} }
      aps['aps']['alert'] = self.alert if self.alert
      aps['aps']['badge'] = self.badge if self.badge
      aps['aps']['sound'] = self.sound if self.sound
      aps['aps']['content-available'] = 1 if self.content_available

      aps.merge!(self.other) if self.other

      #action for notificaton action
      if aps['category']
        aps['aps']['category'] = aps['category']
      end
      aps.to_json
  end
end