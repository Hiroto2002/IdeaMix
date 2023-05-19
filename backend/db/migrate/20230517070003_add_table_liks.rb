class AddTableLiks < ActiveRecord::Migration[6.1]
  def change
     create_table:likes do |t|
      t.integer:post_id
      t.integer:user_id
    end
  end
end
