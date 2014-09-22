class MapContactsWorker
  include Sidekiq::Worker

  def perform(contact_numbers, contact_infos,current_user_id)
    users = User.where(phone_number: contact_numbers)
    contact_numbers -= users.map(&:phone_number)

    existing_prospects = Prospect.where(phone_number: contact_numbers)
    existing_prospects.each do |existing_prospect|
      existing_prospect.contacts_count += 1
      existing_prospect.contact_ids += "," + current_user_id.to_s

      # add facebook id if missing
      if existing_prospect.facebook_id.blank? and !contact_infos[existing_prospect.phone_number][0].blank? and contact_infos[existing_prospect.phone_number][1]
        existing_prospect.facebook_id = contact_infos[existing_prospect.phone_number][0]
      end

      # get facebook id if missing
      if !existing_prospect.facebook_id.blank? and contact_infos[existing_prospect.phone_number][0].blank?
        contact_infos[existing_prospect.phone_number][0] = existing_prospect.facebook_id
        contact_infos[existing_prospect.phone_number][1] = 1
      end

      existing_prospect.save!
    end

    new_prospect_numbers = contact_numbers
    if existing_prospects.length > 0
      new_prospect_numbers -= existing_prospects.map(&:phone_number)
    end

    new_prospect_numbers.each do |phone_number|
      new_prospect = Prospect.new
      new_prospect.phone_number = phone_number
      new_prospect.contacts_count = 1
      new_prospect.contact_ids = current_user_id.to_s
      if !contact_infos[new_prospect.phone_number][0].blank?
        new_prospect.facebook_id = contact_infos[new_prospect.phone_number][0]
      end
      new_prospect.save!
    end
  end
end