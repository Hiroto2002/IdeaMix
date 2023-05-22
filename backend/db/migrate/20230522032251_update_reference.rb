class UpdateReference < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :likes, :users, on_delete: :cascade
    add_foreign_key :comments, :users, on_delete: :cascade
    add_foreign_key :likes, :posts, on_delete: :cascade
  end
end
