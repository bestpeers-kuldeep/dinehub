class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  def self.fetch(key)
    find_by(key: key)&.value
  end

  def self.assign!(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.save!
    setting
  end
end
