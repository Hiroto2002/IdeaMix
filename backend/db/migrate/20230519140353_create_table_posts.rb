class CreateTablePosts < ActiveRecord::Migration[6.1]
  def change
    create_table:posts do |t|
      t.string:title
      t.integer:noun_id
      t.integer:verb_id
      t.text:context
      t.text:question
      t.integer:category_id
      t.boolean:is_open
      t.integer:user_id
      t.timestamp:created_at
    end
  end
end
