# frozen_string_literal: true

module Spree
  class BillingIntegration::OpenpayGateway::Card < Gateway
    preference :auth_token, :string
    preference :public_auth_token, :string
    preference :source_method, :string, default: 'card'
    preference :openpay_id, :string

    unless Rails::VERSION::MAJOR == 4
      attr_accessible :preferred_auth_token, :preferred_public_auth_token, :preferred_source_method, :gateway_response, :preferred_openpay_id
    end

    def provider_class
      Spree::Openpay::Provider
    end

    def payment_source_class
      CreditCard
    end

    def card?
      true
    end

    def auto_capture?
      true
    end

    def with_installments?
      false
    end

    def method_type
      'openpay_card'
    end
  end
end
