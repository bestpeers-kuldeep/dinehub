class Reservation < ApplicationRecord
  validates :email, :phone, presence: true
  
  def self.coerce_time(value)
    return value if value.acts_like?(:time)

    Time.zone.parse(value.to_s)
  end

  def self.sql_time(value)
    coerce_time(value).strftime("%H:%M:%S")
  end

  def parsed_start_time
    self.class.coerce_time(start_time)
  end
end
