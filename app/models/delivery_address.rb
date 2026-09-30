class DeliveryAddress < ApplicationRecord
  LATITUDE_RANGE = (-90..90)
  LONGITUDE_RANGE = (-180..180)

  belongs_to :user
  # Orders keep their history; deleting an address only detaches it.
  has_many :orders, dependent: :nullify

  validates :address_line, :city, :state, :postal_code, presence: true
  validates :latitude, numericality: { in: LATITUDE_RANGE }, allow_nil: true
  validates :longitude, numericality: { in: LONGITUDE_RANGE }, allow_nil: true
  validates :is_default, inclusion: { in: [ true, false ] }

  # Runs inside the save transaction, so demoting the old default and saving the
  # new one is atomic. A partial unique index on (user_id) WHERE is_default backs
  # this at the database level for anything that bypasses callbacks.
  before_save :demote_other_defaults, if: -> { is_default? && will_save_change_to_is_default? }

  scope :ordered, -> { order(is_default: :desc, created_at: :desc) }

  private

  def demote_other_defaults
    user.delivery_addresses
        .where(is_default: true)
        .where.not(id: id)
        .update_all(is_default: false)
  end
end
