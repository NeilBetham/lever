class LogSerializer < ActiveModel::Serializer
  attributes :id, :parts, :complete, :created_at, :updated_at
end
