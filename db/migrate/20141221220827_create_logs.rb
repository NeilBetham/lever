class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.text :parts
      t.boolean :complete, default: false

      t.references :job
      t.timestamps
    end
  end
end
