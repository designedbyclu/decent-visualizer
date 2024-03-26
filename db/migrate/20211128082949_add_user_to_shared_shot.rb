class AddUserToSharedShot < ActiveRecord::Migration[7.0]
  def change
    add_reference :shared_shots, :user, foreign_key: true, type: :uuid
  end
end
