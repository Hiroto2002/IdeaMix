class CreateTableVerbs < ActiveRecord::Migration[6.1]
  def change
    create_table:verbs do |t|
      t.string:name
    end
  end
end
