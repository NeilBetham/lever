class Setting < ActiveRecord::Base
  def self.method_missing(method_name, *args, &block)
    if method_name[-1] == '='
      handle_set_setting method_name.to_s.delete("="), args.first
    else
      handle_get_setting method_name
    end
  end

  private

  def self.handle_get_setting(name)
    if setting = Setting.find_by(key: name.to_s)
      setting.value unless setting.value.empty?
    else
      nil
    end
  end

  def self.handle_set_setting(name, value)
    if setting = Setting.find_or_create_by(key: name.to_s)
      setting if setting.update(value: value.to_s)
    end
  end
end
