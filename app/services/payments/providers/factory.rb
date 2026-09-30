module Payments
  module Providers
    class Factory
      PROVIDERS = {
        "cashfree" => Cashfree::CreateOrder
      }.freeze

      def self.for(gateway)
        PROVIDERS.fetch(gateway.to_s) do
          raise ArgumentError, "Unsupported payment gateway: #{gateway.inspect}"
        end
      end
    end
  end
end
