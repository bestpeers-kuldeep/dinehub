module InquiryReservations
  class Create
    def self.call(reservation_class:, attributes:)
      new(reservation_class: reservation_class, attributes: attributes).call
    end

    def initialize(reservation_class:, attributes:)
      @reservation_class = reservation_class
      @attributes = attributes
    end

    def call
      @reservation_class.create!(Reservations::FullName.assign(@attributes))
    end
  end
end
