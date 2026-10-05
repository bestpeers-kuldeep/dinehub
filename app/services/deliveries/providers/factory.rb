module Deliveries
  module Providers
    class Factory
      def self.for(provider)
        case provider.to_s
        when "borzo"
          Borzo::CreateOrder
        else
          raise ArgumentError, "Unsupported delivery provider: #{provider}"
        end
      end
    end
  end
end
