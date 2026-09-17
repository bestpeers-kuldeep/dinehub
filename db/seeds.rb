# Idempotent seed data for menus, categories, and menu items.

def seed_menu_items!(category, items)
  items.each do |attrs|
    item = category.menu_items.find_or_initialize_by(name: attrs[:name])
    item.description = attrs[:description]
    item.price = attrs[:price]
    item.start_at = attrs[:start_at]
    item.end_at = attrs[:end_at]
    item.save!
  end
end

def seed_category_image!(category, filename)
  image_path = Rails.root.join("db/seeds/images/#{filename}")
  return unless image_path.exist?
  return if category.image.attached? && category.image.filename.to_s == filename && category.image_url.present?

  File.open(image_path, "rb") do |file|
    category.image.attach(
      io: file,
      filename: filename,
      content_type: "image/png"
    )
  end
end

def seed_category!(menu, name:, drink_type: nil, items:, image: "category.png")
  category = menu.menu_categories.find_or_create_by!(name: name) do |c|
    c.drink_type = drink_type
  end
  category.update!(drink_type: drink_type) if category.drink_type != drink_type
  seed_menu_items!(category, items)
  seed_category_image!(category, image)
  category
end

def week_day(weekday_name)
  (Date.current..(Date.current + 6)).find { |date| date.strftime("%A").downcase == weekday_name.to_s }
end

def day_range(weekday_name)
  date = week_day(weekday_name)
  return { start_at: nil, end_at: nil } unless date

  { start_at: date.beginning_of_day, end_at: date.end_of_day }
end

# --- Our Menu (food) ---
our_menu = Menu.find_or_create_by!(name: "Our Menu") do |menu|
  menu.category_type = :our_menu
end
our_menu.update!(category_type: :our_menu)

seed_category!(our_menu, name: "Starters", items: [
  { name: "Tomato Bruschetta", description: "Toasted bread with tomatoes, basil, and olive oil", price: 8.50 },
  { name: "Soup of the Day", description: "Chef's daily soup with fresh bread", price: 7.00 },
  { name: "Caesar Salad", description: "Romaine, parmesan, croutons, Caesar dressing", price: 9.50 }
])

seed_category!(our_menu, name: "Mains", items: [
  { name: "Grilled Salmon", description: "Atlantic salmon with seasonal vegetables", price: 22.00 },
  { name: "Ribeye Steak", description: "12oz ribeye with fries and house sauce", price: 28.00 },
  { name: "Mushroom Risotto", description: "Creamy arborio rice with wild mushrooms", price: 18.50 }
])

seed_category!(our_menu, name: "Desserts", items: [
  { name: "Chocolate Lava Cake", description: "Warm chocolate cake with vanilla ice cream", price: 9.00 },
  { name: "Tiramisu", description: "Classic espresso-soaked ladyfingers and mascarpone", price: 8.50 }
])

# --- Specials — items timed with start_at / end_at for the current week ---
specials = Menu.find_or_create_by!(name: "Specials") do |menu|
  menu.category_type = :specials
end
specials.update!(category_type: :specials)

# Drop old day-named / available_on-based categories if re-seeding
specials.menu_categories.where(name: [
  "Monday Special", "Tuesday Special", "Wednesday Special", "Thursday Special",
  "Friday Special", "Saturday Special", "Sunday Special"
]).find_each(&:destroy!)

seed_category!(specials, name: "Chef Specials", items: [
  { name: "Truffle Pasta", description: "Fresh tagliatelle with black truffle cream", price: 26.00, **day_range(:tuesday) },
  { name: "Taco Tuesday Plate", description: "Three street tacos with salsa and rice", price: 15.00, **day_range(:tuesday) },
  { name: "Duck Confit", description: "Slow-cooked duck leg with cherry reduction", price: 24.50, **day_range(:thursday) },
  { name: "Steak Night", description: "8oz sirloin with fries and sauce", price: 27.00, **day_range(:thursday) },
  { name: "Seafood Platter", description: "Assorted fresh seafood for two", price: 48.00, **day_range(:friday) },
  { name: "Fish Fry", description: "Beer-battered catch with tartar sauce", price: 19.00, **day_range(:friday) },
  { name: "Weekend Brunch Burger", description: "Smash burger with egg and hash brown", price: 17.50, **day_range(:saturday) },
  { name: "Sunday Roast", description: "Roast chicken, potatoes, gravy", price: 21.00, **day_range(:sunday) }
])

seed_category!(specials, name: "Seasonal", items: [
  { name: "Pumpkin Ravioli", description: "House-made ravioli with sage butter", price: 19.00, **day_range(:wednesday) },
  { name: "Berry Pavlova", description: "Meringue with seasonal berries and cream", price: 10.00, **day_range(:monday) }
])

# --- Drinks ---
drinks = Menu.find_or_create_by!(name: "Drinks") do |menu|
  menu.category_type = :drinks
end
drinks.update!(category_type: :drinks)

seed_category!(drinks, name: "Draft Beers", drink_type: :beer, items: [
  { name: "House Lager", description: "Crisp draft lager, pint", price: 6.00 },
  { name: "IPA Draft", description: "Hop-forward India Pale Ale, pint", price: 7.50 },
  { name: "Stout Draft", description: "Rich dark stout, pint", price: 7.00 }
])

seed_category!(drinks, name: "Bottled Beers", drink_type: :beer, items: [
  { name: "Pale Ale Bottle", description: "330ml craft pale ale", price: 5.50 },
  { name: "Wheat Beer Bottle", description: "330ml Belgian-style wheat", price: 6.00 }
])

seed_category!(drinks, name: "Red Wines", drink_type: :wine, items: [
  { name: "House Cabernet", description: "Full-bodied red, glass", price: 9.00 },
  { name: "Malbec Reserve", description: "Argentine malbec, glass", price: 11.00 },
  { name: "Pinot Noir", description: "Light elegant red, glass", price: 10.50 }
])

seed_category!(drinks, name: "White Wines", drink_type: :wine, items: [
  { name: "House Sauvignon Blanc", description: "Crisp white, glass", price: 8.50 },
  { name: "Chardonnay", description: "Oaked chardonnay, glass", price: 10.00 }
])

seed_category!(drinks, name: "Classic Cocktails", drink_type: :cocktails, items: [
  { name: "Old Fashioned", description: "Whiskey, bitters, sugar, orange", price: 12.00 },
  { name: "Margarita", description: "Tequila, triple sec, lime", price: 11.00 },
  { name: "Martini", description: "Gin or vodka, dry vermouth", price: 13.00 }
])

seed_category!(drinks, name: "Signature Cocktails", drink_type: :cocktails, items: [
  { name: "Dinehub Smash", description: "House bourbon smash with seasonal fruit", price: 14.00 },
  { name: "Garden Spritz", description: "Aperitivo, prosecco, herb syrup", price: 12.50 }
])

seed_category!(drinks, name: "Vodka & Gin", drink_type: :spirits, items: [
  { name: "Premium Vodka", description: "Single pour, neat or rocks", price: 9.00 },
  { name: "London Dry Gin", description: "Single pour with tonic option", price: 9.50 },
  { name: "Flavored Vodka", description: "Citrus or berry infused vodka", price: 10.00 }
])

seed_category!(drinks, name: "Rum & Tequila", drink_type: :spirits, items: [
  { name: "Aged Rum", description: "Dark aged rum, single pour", price: 10.00 },
  { name: "Blanco Tequila", description: "100% agave blanco, single pour", price: 9.50 }
])

seed_category!(drinks, name: "Scotch", drink_type: :whiskey, items: [
  { name: "Speyside Single Malt", description: "12-year single malt, neat", price: 14.00 },
  { name: "Islay Peated", description: "Smoky Islay malt, neat", price: 16.00 },
  { name: "Blended Scotch", description: "Smooth house blend", price: 11.00 }
])

seed_category!(drinks, name: "Bourbon", drink_type: :whiskey, items: [
  { name: "Kentucky Bourbon", description: "Classic bourbon, neat or rocks", price: 12.00 },
  { name: "Small Batch Bourbon", description: "Small-batch reserve pour", price: 15.00 }
])

# --- Events ---
def seed_event_item!(event, attrs)
  item = event.event_items.find_or_initialize_by(title: attrs[:title])
  item.description = attrs[:description]
  item.event_date = attrs[:event_date]
  item.start_time = attrs[:start_time]
  item.end_time = attrs[:end_time]
  item.save!

  logo_path = Rails.root.join("db/seeds/logos/#{attrs[:logo]}")
  if logo_path.exist? && (!item.logo.attached? || item.logo.filename.to_s != attrs[:logo] || item.logo_url.blank?)
    File.open(logo_path, "rb") do |file|
      item.logo.attach({
        io: file,
        filename: attrs[:logo],
        content_type: "image/png"
      })
    end
  end

  item
end

event = Event.find_or_create_by!(name: "Event")
sports = Event.find_or_create_by!(name: "Sports")

seed_event_item!(event, {
  title: "Live Music Night",
  description: "Local band performing acoustic sets in the lounge",
  event_date: Date.current + 1,
  start_time: "19:00",
  end_time: "22:00",
  logo: "live-music.png"
})

seed_event_item!(event, {
  title: "Jazz Evening",
  description: "Smooth jazz with dinner pairings",
  event_date: Date.current + 3,
  start_time: "20:00",
  end_time: "23:00",
  logo: "jazz-night.png"
})

seed_event_item!(event, {
  title: "Trivia Night",
  description: "Team quiz with prizes and drink specials",
  event_date: Date.current + 5,
  start_time: "18:30",
  end_time: "21:00",
  logo: "trivia-night.png"
})

seed_event_item!(sports, {
  title: "Match Day Screening",
  description: "Big-screen football match with game-day bites",
  event_date: Date.current,
  start_time: "17:00",
  end_time: "20:00",
  logo: "match-day.png"
})

seed_event_item!(sports, {
  title: "Watch Party",
  description: "Championship watch party with shared platters",
  event_date: Date.current + 2,
  start_time: "18:00",
  end_time: "21:30",
  logo: "watch-party.png"
})

seed_event_item!(sports, {
  title: "Fitness Morning",
  description: "Outdoor stretch session followed by healthy breakfast",
  event_date: Date.current + 4,
  start_time: "07:30",
  end_time: "09:00",
  logo: "fitness-morning.png"
})

# --- Tables ---
Table.where(name: [ "Table 1", "Table 2", "Table 3", "Table 4", "Table 5", "VIP-1" ]).find_each(&:destroy!)

capacities = [ 2, 4, 6 ]
Table.locations.each_key do |location|
  capacities.each_with_index do |capacity, index|
    name = "#{location} #{index + 1}"
    table = Table.find_or_initialize_by(name: name)
    table.capacity = capacity
    table.location = location
    table.save!
  end
end

puts "Seeded menus: #{Menu.count}, categories: #{MenuCategory.count}, items: #{MenuItem.count}"
puts "Seeded events: #{Event.count}, event_items: #{EventItem.count}"
puts "Seeded tables: #{Table.count}"

# --- Reservations ---
# Cocktail Bar 1 is booked 11:30–12:00 today; 12:30 and 13:00 stay free.
cocktail_bar_one = Table.find_by!(name: "Cocktail Bar 1")
unless cocktail_bar_one.reservations.overlapping(Date.current, "11:30").exists?
  cocktail_bar_one.reservations.create!(
    reservation_date: Date.current,
    start_time: "11:30",
    first_name: "Alex",
    last_name: "Guest",
    email: "alex@example.com",
    phone: "555-0100"
  )
end

puts "Seeded reservations: #{Reservation.count}"
