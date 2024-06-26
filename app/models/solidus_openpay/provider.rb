# frozen_string_literal: true

module SolidusOpenpay
  class Provider
    include Spree::Openpay::Client

    attr_accessor :auth_token, :source_method, :openpay_id

    attr_reader :options

    PAYMENT_SOURCES = {
        'card' => Spree::Openpay::PaymentSource::Card,
        'bank' => Spree::Openpay::PaymentSource::Bank,
        'cash' => Spree::Openpay::PaymentSource::Cash
    }

    def initialize(options = {})
      @options       = options
      @auth_token    = options[:auth_token]
      @openpay_id    = options[:openpay_id]
      @source_method = payment_processor(options[:source_method])
    end

    def authorize(amount, method_params, gateway_options = {})
      common = build_common(amount, method_params, gateway_options)
      commit common, method_params, gateway_options
    end

    alias_method :purchase, :authorize

    def capture(amount, method_params, gateway_options = {})
      Response.new({}, gateway_options)
    end

    def endpoint
      "charges"
    end
    
    def merchant_id
      return @openpay_id
    end

    def payment_processor(source_name)
      PAYMENT_SOURCES[source_name]
    end

    def supports?(brand)
      %w(visa master).include? brand
    end

    def credit(credit_cents, response_code, gateway_options)
      Spree::Openpay::FakeResponse.new
    end

    private

    def commit(common, method_params, gateway_options)
      #We do not use this to add card and monthly_installments
      if source_method != Spree::Openpay::PaymentSource::Card
        source_method.request(common, method_params, gateway_options)
      end
      Spree::Openpay::Response.new post(common), source_method
    end

    def build_common(amount, method, gateway_params)
      #Find Spree::Order
      order = Spree::Order.find_by_number(gateway_params[:order_id].split('-').first)
      amount_money = order.total.to_f
      
      if source_method == Spree::Openpay::PaymentSource::Cash && gateway_params[:currency] != 'MXN'
        return build_common_to_cash(amount, gateway_params) 
      else
        device_session_id = (order.device_session_id.nil? ? "" : order.device_session_id) 
        
        {
          "source_id" => method.gateway_payment_profile_id,
          "method" => "card",
          "amount" => amount_money,
          "currency" => gateway_params[:currency],
          "description" => gateway_params[:order_id],
          "order_id" => gateway_params[:order_id],
          "device_session_id" => device_session_id,
          "customer" => customer(gateway_params)
        }
      end
    end
  
    def customer(gateway_params)
      order = Spree::Order.find_by_number(gateway_params[:order_id].split('-').first)
      bill_address = order.bill_address
      name = (bill_address.first_name? ? bill_address.first_name : gateway_params[:billing_address][:name])
      last_name = (bill_address.last_name? ? bill_address.last_name : gateway_params[:billing_address][:name])
        
      {
        "name" => name,
        "last_name" => last_name,
        "phone_number" => gateway_params[:billing_address][:phone],
        "email" => gateway_params[:email]
      }
    end

    def details(gateway_params)
      {
        'name'            => gateway_params[:billing_address][:name],
        'email'           => gateway_params[:email],
        'phone'           => gateway_params[:billing_address][:phone],
        'billing_address' => billing_address(gateway_params),
        'line_items'      => line_items(gateway_params),
        'shipment'        => shipment(gateway_params)
      }
    end

    def shipping_address(gateway_params)
      {
        'street1' => gateway_params[:shipping_address][:address1],
        'street2' => gateway_params[:shipping_address][:address2],
        'city'    => gateway_params[:shipping_address][:city],
        'state'   => gateway_params[:shipping_address][:state],
        'country' => gateway_params[:shipping_address][:country],
        'zip'     => gateway_params[:shipping_address][:zip]
      }
    end

    def billing_address(gateway_params)
      {
        'email'   => gateway_params[:email],
        'street1' => gateway_params[:billing_address][:address1],
        'street2' => gateway_params[:billing_address][:address2],
        'city'    => gateway_params[:billing_address][:city],
        'state'   => gateway_params[:billing_address][:state],
        'country' => gateway_params[:billing_address][:country],
        'zip'     => gateway_params[:billing_address][:zip]
      }
    end

    def line_items(gateway_params)
      order = Spree::Order.find_by_number(gateway_params[:order_id].split('-').first)
      order.line_items.map(&:to_conekta)
    end

    def shipment(gateway_params)
      order = Spree::Order.find_by_number(gateway_params[:order_id].split('-').first)
      shipment = order.shipments[0]
      carrier = (shipment.present? ? shipment.shipping_method.name : "other")
      traking_id = (shipment.present? ? shipment.tracking : nil)
      {
        'price'   => gateway_params[:shipping],
        'address' => shipping_address(gateway_params),
        'service'     => "other",
        'carrier'     => carrier,
        'tracking_id'  => traking_id
      }
    end
    
    def build_common_to_cash(amount, gateway_params)
      amount_exchanged = Spree::Openpay::Exchange.new(amount, gateway_params[:currency]).amount_exchanged
      {
         'amount' => amount_exchanged,
         'reference_id' => gateway_params[:order_id],
         'currency' => "MXN",
         'description' => gateway_params[:order_id],
         'details' => details(gateway_params)
      }
    end
  end
end
