$(document).ready ->
  if action() == "edit" and controller() == "contributions" and namespace() == "unlockmoip"
    $('#pay_form').on "submit", (event) ->
      event.preventDefault()
      event.stopPropagation()
      form = $(@)
      submit = form.find('[type=submit]')
      return unless submit.is(':visible')
      submit.hide()
      billing_info_ok = false
      status = form.find('.gateway_data')
      terms = form.find('#terms')
      status.removeClass 'success'
      status.removeClass 'failure'
      status.find('ul').html('')
      unless terms.is(':checked')
        status.addClass 'failure'
        status.html("<h4>Você precisa aceitar os termos de uso para continuar.</h4>")
        status.show()
        submit.show()
      else
        status.html("<h4>Enviando dados de pagamento para o Moip...</h4><ul></ul>")
        status.show()
        if MoipAssinaturas?
          moip = new MoipAssinaturas(form.data('token'))
          moip.callback (response) ->
            status.find('h4').html("#{response.message} (Moip)")
            unless response.has_errors()
              unless billing_info_ok
                billing_info_ok = true
                subscription = new Subscription()
                subscription.with_code(form.data('subscription'))
                subscription.with_customer(customer)
                subscription.with_plan_code(form.data('plan'))
                moip.subscribe(subscription)
              else
                $('form.edit_contribution').submit()
            else
              status.addClass 'failure'
              for error in response.errors
                status.find('ul').append("<li>#{error.description}</li>")
              submit.show()
          billing_info =
            fullname: $("#holder_name").val(), 
            expiration_month: $("#expiration_month").val(),
            expiration_year: $("#expiration_year").val(),
            credit_card_number: $("#number").val()
          customer = new Customer()
          customer.code = form.data('customer')
          customer.billing_info = new BillingInfo(billing_info)
          moip.update_credit_card(customer)
        else
          status.addClass 'failure'
          status.find('h4').html("Erro ao carregar o Moip Assinaturas. Por favor, recarregue a página e tente novamente.")
          submit.show()
