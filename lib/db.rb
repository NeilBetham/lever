module DB
  def init
    ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'auto-convert.sqlite3.db'
    )

    ActiveRecord::Schema.define do
      unless ActiveRecord::Base.connection.tables.include? 'jobs'
        create_table :jobs do |table|
          table.column :job_name, :string
          table.column :input_file_name, :string
          table.column :output_file_name, :string
          table.column :job_state, :string
          table.column :iso, :boolean
          table.column :progress, :decimal
        end
      end

      unless ActiveRecord::Base.connection.tables.include? 'settings'
        create_table :setttings do |table|
          table.column :key, :string
          table.column :value, :string
        end
      end
    end
  end

  module_function :init
end
