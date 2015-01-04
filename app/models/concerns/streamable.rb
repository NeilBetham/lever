module Streamable
  extend ActiveSupport::Concern

  included do
    after_create { |model|  model.message 'create' }
    after_update { |model|  model.message 'update' }
    after_destroy { |model|  model.message 'destroy' }
  end

  def message action
    msg = {
      type: "model:#{action}",
      data: {
        modelName: self.class.name.downcase,
        modelId: id,
        data: self
      }
    }

    LeverApp.settings.event_channel.push msg.to_json
  end
end
