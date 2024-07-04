class UserCreation < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string 'name', null: false
      t.timestamps

      t.jsonb :hook_config
    end

    create_table :activity_types do |t|
      t.string 'name', null: false
      t.string 'category'
      t.string 'color'
    end

    create_table :activities do |t|
      t.references :activity_type, null: false
      t.references :user, null: false

      t.timestamp :tstart, null: false
      t.timestamp :tend

      t.string :description

      t.jsonb :extra_flags
    end
  end
end
