
class AddUserLocationTracking < ActiveRecord::Migration[6.0]
  def change
    create_table :user_locations do |table|
      table.references :user, null: false

      table.datetime :ts, null: false

      table.float :lat, null: false
      table.float :lon, null: false
      table.float :velocity
      table.float :elevation
    end

    change_column :activities, :tstart, :datetime, null: false
    change_column :activities, :tend, :datetime
  end
end
