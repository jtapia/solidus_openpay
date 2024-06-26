# frozen_string_literal: true

module SolidusOpenpay
  class CreditCardCollection
    include Enumerable
    include Spree::Openpay::Client

    extend  Forwardable

    def_instance_delegators :@cards, :each, :size

    attr_reader :customer

    def initialize(customer, options)
      @customer   = customer
      @auth_token = options[:auth_token]
      @cards      = build_cards(get)
    end

    def add(token)
        card = Spree::Openpay::CreditCard.create(customer, token, auth_token)
        @cards << card
        card
    end

    def endpoint
      "customers/#{customer.id}/cards"
    end

    private

    def build_cards(response)
      response.map do |credit_card|
        Spree::Openpay::CreditCard.build(customer, credit_card, auth_token: auth_token)
      end
    end
  end
end
