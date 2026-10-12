
module Deliveries
  module Providers
    class Factory
      PROVIDERS = {
        "borzo" => {
          create_order: Borzo::CreateOrder,
          status_mapper: Borzo::StatusMapper
        }
      }.freeze

      def self.for(provider)
        PROVIDERS.dig(provider.to_s, :create_order) ||
          raise(ArgumentError, "Unsupported delivery provider: #{provider}")
      end

      def self.status_mapper_for(provider)
        PROVIDERS.dig(provider.to_s, :status_mapper) ||
          raise(ArgumentError, "Unsupported delivery provider: #{provider}")
      end
    end
  end
end
