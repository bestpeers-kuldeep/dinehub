module InquiryReservation
  extend ActiveSupport::Concern

  included do
    validates :full_name, :reservation_date, :start_time, presence: true
    validates :duration, :budget_per_person, :occasion, :source, presence: true
    validates :budget_per_person, numericality: { greater_than: 0 }
    validates :number_of_people, numericality: { only_integer: true, greater_than: 0 }

    after_create_commit :send_inquiry_received_email
  end

  def inquiry_kind
    is_a?(CateringReservation) ? "catering" : "party"
  end

  def send_inquiry_received_email
    InquiryReservationMailer.inquiry_received(self).deliver_later
  end

  def as_public_json
    {
      id: id,
      type: type,
      full_name: full_name,
      phone: phone,
      email: email,
      company: company,
      reservation_date: reservation_date,
      start_time: parsed_start_time.strftime("%H:%M"),
      duration: duration,
      budget_per_person: budget_per_person,
      number_of_people: number_of_people,
      occasion: occasion,
      description: description,
      special_requests: special_requests,
      source: source,
      marketing_opt_in: marketing_opt_in
    }
  end
end
