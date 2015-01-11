class JobSerializer < ActiveModel::Serializer
  attributes :id, :name, :input_folder, :input_file_name, :output_file_name, :state, :iso, :progress, :created_at, :updated_at
  has_many :logs
end
