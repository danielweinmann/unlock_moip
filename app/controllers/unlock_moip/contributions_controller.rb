class UnlockMoip::ContributionsController < ::ApplicationController

  is_unlock_gateway

  def create

    # Getting the date from Pickadate
    if params[:pickadate_birthdate_submit]
      params[:contribution][:user_attributes][:birthdate] = params[:pickadate_birthdate_submit]
    end
    
    if create_contribution

      data = {}
      # Storing the customer_code and subscription_code
      data["customer_code"] = @contribution.customer_code
      data["subscription_code"] = @contribution.subscription_code
      # Storing user information
      data["email"] = @contribution.user.email
      data["full_name"] = @contribution.user.full_name
      data["document"] = @contribution.user.document
      data["phone_area_code"] = @contribution.user.phone_area_code
      data["phone_number"] = @contribution.user.phone_number
      data["birthdate"] = @contribution.user.birthdate
      data["address_street"] = @contribution.user.address_street
      data["address_number"] = @contribution.user.address_number
      data["address_complement"] = @contribution.user.address_complement
      data["address_district"] = @contribution.user.address_district
      data["address_city"] = @contribution.user.address_city
      data["address_state"] = @contribution.user.address_state
      data["address_zipcode"] = @contribution.user.address_zipcode
      # Saving gateway_data
      @contribution.update gateway_data: data

      # Creating the plan, if needed
      begin
        response = Moip::Assinaturas::Plan.details(@contribution.plan_code, @contribution.moip_auth)
      rescue Moip::Assinaturas::WebServerResponseError => e
        if @contribution.gateway.sandbox?
          @contribution.errors.add(:base, "Parece que este Unlock não está autorizado a utilizar o ambiente de Sandbox do Moip Assinaturas.#{ ' Você já solicitou acesso ao Moip Assinaturas? Verifique também se configurou o Token e a Chave de API.' if @initiative.user == current_user }")
        else
          @contribution.errors.add(:base, "Parece que este Unlock não está autorizado a utilizar o ambiente de produção do Moip Assinaturas.#{ ' Você já homologou sua conta para produção no Moip Assinaturas? Verifique também se configurou o Token e a Chave de API.' if @initiative.user == current_user }")
        end
        return render '/initiatives/contributions/new'
      rescue => e
        @contribution.errors.add(:base, "Ocorreu um erro de conexão ao verificar o plano de assinaturas no Moip. Por favor, tente novamente.")
        return render '/initiatives/contributions/new'
      end
      unless response[:success]
        plan = {
          code: @contribution.plan_code,
          name: @contribution.plan_name,
          amount: (@contribution.value * 100).to_i
        }
        begin
          response = Moip::Assinaturas::Plan.create(plan, @contribution.moip_auth)
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao criar o plano de assinaturas no Moip. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
        unless response[:success]
          if response[:errors] && response[:errors].kind_of?(Array)
            response[:errors].each do |error|
              @contribution.errors.add(:base, "#{response[:message]} (Moip). #{error[:description]}")
            end
          else
            @contribution.errors.add(:base, "Ocorreu um erro ao criar o plano de assinaturas no Moip. Por favor, tente novamente.")
          end
          return render '/initiatives/contributions/new'
        end
      end

      # Creating the client, if needed
      customer = {
        code: @contribution.customer_code,
        email: @contribution.user.email,
        fullname: @contribution.user.full_name,
        cpf: @contribution.user.document,
        phone_area_code: @contribution.user.phone_area_code,
        phone_number: @contribution.user.phone_number,
        birthdate_day: @contribution.user.birthdate.strftime('%d'),
        birthdate_month: @contribution.user.birthdate.strftime('%m'),
        birthdate_year: @contribution.user.birthdate.strftime('%Y'),
        address: {
          street: @contribution.user.address_street,
          number: @contribution.user.address_number,
          complement: @contribution.user.address_complement,
          district: @contribution.user.address_district,
          city: @contribution.user.address_city,
          state: @contribution.user.address_state,
          country: "BRA",
          zipcode: @contribution.user.address_zipcode
        }
      }
      begin
        response = Moip::Assinaturas::Customer.details(@contribution.customer_code, @contribution.moip_auth)
      rescue
        @contribution.errors.add(:base, "Ocorreu um erro de conexão ao verificar o cadastro de cliente no Moip. Por favor, tente novamente.")
        return render '/initiatives/contributions/new'
      end
      if response[:success]
        begin
          response = Moip::Assinaturas::Customer.update(@contribution.customer_code, customer, @contribution.moip_auth)
          unless response[:success]
            if response[:errors] && response[:errors].kind_of?(Array)
              response[:errors].each do |error|
                @contribution.errors.add(:base, "#{response[:message]} (Moip). #{error[:description]}")
              end
            else
              @contribution.errors.add(:base, "Ocorreu um erro ao atualizar o cadastro de cliente no Moip. Por favor, tente novamente.")
            end
            return render '/initiatives/contributions/new'
          end
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao atualizar o cadastro de cliente no Moip. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
      else
        begin
          response = Moip::Assinaturas::Customer.create(customer, new_vault = false, @contribution.moip_auth)
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao realizar o cadastro de cliente no Moip. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
        unless response[:success]
          if response[:errors] && response[:errors].kind_of?(Array)
            response[:errors].each do |error|
              @contribution.errors.add(:base, "#{response[:message]} (Moip). #{error[:description]}")
            end
          else
            @contribution.errors.add(:base, "Ocorreu um erro ao realizar o cadastro de cliente no Moip. Por favor, tente novamente.")
          end
          return render '/initiatives/contributions/new'
        end
      end

      flash[:success] = "Apoio iniciado com sucesso! Agora é só realizar o pagamento :D"
      return redirect_to edit_moip_contribution_path(@contribution)

    end
    
  end

end
