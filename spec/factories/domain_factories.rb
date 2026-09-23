FactoryBot.define do
  sequence(:email) { |n| "guest#{n}@example.com" }
  sequence(:phone) { |n| "555-#{n.to_s.rjust(4, "0")}" }
  sequence(:table_name) { |n| "Table #{n}" }

  factory :user do
    first_name { "Alex" }
    last_name { "Guest" }
    email
    phone
    password { "password123" }
  end

  factory :career do
    full_name { "Alex Guest" }
    email
    phone
    experience { "5 years front of house" }

    trait :with_external_resume do
      resume_link { "https://example.com/resume.pdf" }
    end

    trait :with_resume do
      transient do
        resume_contents { "%PDF-1.4 fake resume" }
        resume_filename { "resume.pdf" }
        resume_content_type { "application/pdf" }
      end

      after(:create) do |career, evaluator|
        career.resume.attach(
          io: StringIO.new(evaluator.resume_contents),
          filename: evaluator.resume_filename,
          content_type: evaluator.resume_content_type
        )
      end
    end
  end

  factory :menu do
    sequence(:name) { |n| "Menu #{n}" }
    category_type { :our_menu }

    trait :drinks do
      category_type { :drinks }
    end
  end

  factory :menu_category do
    menu
    sequence(:name) { |n| "Category #{n}" }

    trait :beer do
      drink_type { :beer }
    end
  end

  factory :menu_item do
    menu_category
    sequence(:name) { |n| "Menu Item #{n}" }
    description { "A menu item description" }
    price { 8.50 }

    trait :with_image do
      transient do
        image_contents { "fake-image" }
        image_filename { "menu-item.jpg" }
        image_content_type { "image/jpeg" }
      end

      after(:create) do |item, evaluator|
        item.image.attach(
          io: StringIO.new(evaluator.image_contents),
          filename: evaluator.image_filename,
          content_type: evaluator.image_content_type
        )
      end
    end
  end

  factory :table do
    name { generate(:table_name) }
    capacity { 4 }
    location { "Cocktail Bar" }

    trait :covered_patio do
      location { "Covered Patio" }
    end
  end

  factory :reservation do
    reservation_date { Date.new(2026, 9, 16) }
    start_time { "11:30" }
    full_name { "Alex Guest" }
    email
    phone

    factory :table_reservation, class: "TableReservation" do
      table

      trait :dinner do
        start_time { "18:00" }
      end
    end

    factory :parties_reservation, class: "PartiesReservation" do
      start_time { "18:00" }
      company { "Acme" }
      duration { "2 hours" }
      budget_per_person { 45.00 }
      number_of_people { 20 }
      occasion { "Birthday" }
      description { "Birthday dinner for 20" }
      source { "website" }
    end

    factory :catering_reservation, class: "CateringReservation" do
      start_time { "18:00" }
      company { "Northwind" }
      duration { "2 hours" }
      budget_per_person { 45.00 }
      number_of_people { 20 }
      occasion { "Corporate event" }
      description { "Catering for 20" }
      source { "website" }
    end
  end

  factory :event do
    sequence(:name) { |n| "Event #{n}" }
  end

  factory :event_item do
    event
    sequence(:title) { |n| "Event Item #{n}" }
    description { "An event description" }
    event_date { Date.new(2026, 9, 16) }
    start_time { "19:00" }
    end_time { "22:00" }
  end
end
