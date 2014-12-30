collection [@log] => :logs
attributes :parts, :complete, :created_at, :updated_at
child(:job) { attributes :id }
