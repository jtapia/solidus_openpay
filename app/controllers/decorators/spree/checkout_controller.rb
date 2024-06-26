# frozen_string_literal: true

module Decorators
  module Spree
    module CheckoutController
      def self.prepended(base)
        base.before_action :add_device_session, only: :update

        if Rails::VERSION::MAJOR >= 4
          base.before_action :permit_installments_number
          base.before_action :permit_conekta_response
        end
      end

      def add_device_session
        unless @order.completed?
          if params[:deviceIdHiddenFieldName].present?
            @order.update(device_session_id: params[:deviceIdHiddenFieldName])
          end
        end
      end

      def completion_route
        if @order.payments.present? && conekta_payment?(@order.payments.last.payment_method)
           openpay_payment_path(@order)
        else
          spree.order_path(@order)
        end
      end

      private

      def conekta_payment?(payment_method)
        [
            Spree::BillingIntegration::OpenpayGateway::Bank,
            Spree::BillingIntegration::OpenpayGateway::Cash
        ].include? payment_method.class
      end

      def permit_installments_number
        permitted_source_attributes << :installments_number
      end

      def permit_conekta_response
        permitted_source_attributes << :conekta_response
      end

      Spree::CheckoutController.prepend(self)
    end
  end
end
