class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :menu_item

  validates :quantity, numericality: { greater_than: 0 }

  after_save :refresh_cart_checkout
  after_destroy :refresh_cart_checkout

  private

  def refresh_cart_checkout
    cart.refresh_open_checkout!
  end
end
