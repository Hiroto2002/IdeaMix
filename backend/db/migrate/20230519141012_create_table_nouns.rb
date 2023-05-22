class CreateTableNouns < ActiveRecord::Migration[6.1]
  def change
    create_table:nouns do |t|
      t.string:name
    end
  end
end
