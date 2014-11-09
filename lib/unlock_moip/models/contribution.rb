module UnlockMoip
  module Models
    module Contribution

      include UnlockGateway::Models::Contribution

      def moip_auth
        return {} unless self.gateway && self.gateway.settings
        { moip_auth: { token: self.gateway.settings["token"], key: self.gateway.settings["key"], sandbox: self.gateway.sandbox? }}
      end

      def plan_code
        "#{self.initiative.permalink[0..29]}#{self.value.to_i}#{'sandbox' if self.gateway.sandbox?}"
      end

      def plan_name
        "#{self.initiative.name[0..29]} #{self.value.to_i}#{' (Sandbox)' if self.gateway.sandbox?}"
      end
    
      def customer_code
        if self.gateway_data && self.gateway_data["customer_code"]
          self.gateway_data["customer_code"]
        else
          Digest::MD5.new.update("#{self.initiative.permalink[0..29]}#{self.user.id}#{'sandbox' if self.gateway.sandbox?}").to_s
        end
      end
      
      def subscription_code
        if self.gateway_data && self.gateway_data["subscription_code"]
          self.gateway_data["subscription_code"]
        else
          Digest::MD5.new.update("#{self.initiative.permalink[0..29]}#{self.id}#{'sandbox' if self.gateway.sandbox?}").to_s
        end
      end

      def gateway_identifier
        self.gateway_data && self.gateway_data["subscription_code"]
      end

      def state_on_gateway
        begin
          response = Moip::Assinaturas::Subscription.details(self.subscription_code, self.moip_auth)
        rescue
          return nil
        end
        if response && response[:success]
          status = (response[:subscription]["status"].upcase rescue nil)
          case status
            when 'ACTIVE', 'OVERDUE'
              :active
            when 'SUSPENDED', 'EXPIRED', 'CANCELED'
              :suspended
          end
        end
      end

      def update_state_on_gateway!(state)
        transition = self.transition_by_state(state)
        response = Moip::Assinaturas::Subscription.send(transition, self.subscription_code, self.moip_auth)
        response[:success]
      end

    end
  end
end
