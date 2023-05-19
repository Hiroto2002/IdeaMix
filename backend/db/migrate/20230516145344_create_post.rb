class CreatePost < ActiveRecord::Migration[6.1]
  def change
    create_table:posts do |t|
      t.string:artist
      t.string:album
      t.string:music
      t.string:link
      t.string:img
      t.string:comment
      t.string:user_id
    end
  end
end
