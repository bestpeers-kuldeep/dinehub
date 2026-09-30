module Payments
  module Providers
    class Factory
      PROVIDERS = {
        "cashfree" => Cashfree::CreateOrder
      }.freeze

      def self.for(gateway)
        PROVIDERS.fetch(gateway)
      end
    end
  end
end
