collection [@log] => :logs
attributes :id, :parts, :complete, :created_at, :updated_at
child(:job) { attributes :id }
