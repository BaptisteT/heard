class AddStatsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :nb_contacts, :integer
    add_column :users, :nb_contacts_users, :integer

    add_column :users, :nb_contacts_photos, :integer
    add_column :users, :nb_contacts_favorites, :integer
    add_column :users, :nb_contacts_facebook, :integer
    add_column :users, :nb_contacts_photo_only, :integer
    add_column :users, :nb_contacts_family, :integer
    add_column :users, :nb_contacts_related, :integer
    add_column :users, :nb_contacts_linked, :integer
  end
end
