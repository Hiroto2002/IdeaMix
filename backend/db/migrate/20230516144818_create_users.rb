class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table:users do |t|
      t.string:name
      t.integer:password_digest
      t.string:img
    end
  end
end
