class CreateTableComments < ActiveRecord::Migration[6.1]
  def change
    create_table:comments do |t|
      t.text:comment
      t.integer:user_id
      t.integer:post_id
      t.timestamp:created_at
    end
  end
end
