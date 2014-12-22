class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :name
      t.string :input_folder
      t.string :input_file_name
      t.string :output_file_name
      t.string :state
      t.boolean :iso, default: false
      t.decimal :progress, default: 0.0

      t.timestamps
    end
  end
end
