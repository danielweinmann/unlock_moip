$(document).ready ->
  if action() == "edit" and controller() == "contributions" and namespace() == "unlockmoip"
    $('#pay_form [type=submit]').on "click", (event) ->
      event.preventDefault()
      event.stopPropagation()
      billing_info_ok = false
      form = $('#pay_form')
      submit = form.find('[type=submit]')
      status = form.find('.gateway_data')
      terms = form.find('#terms')
      status.removeClass 'success'
      status.removeClass 'failure'
      status.find('ul').html('')
      unless terms.is(':checked')
        status.addClass 'failure'
        status.html("<h4>Você precisa aceitar os termos de uso para continuar.</h4>")
        status.show()
      else
        status.html("<h4>Enviando dados de pagamento para o Moip...</h4><ul></ul>")
        token = form.data('token')
        plan_code = form.data('plan')
        submit.hide()
        status.show()
        if MoipAssinaturas?
          moip = new MoipAssinaturas(token)
          moip.callback (response) ->
            status.find('h4').html("#{response.message} (Moip)")
            unless response.has_errors()
              unless billing_info_ok
                billing_info_ok = true
                subscription = new Subscription()
                subscription.with_code(form.data('subscription'))
                subscription.with_customer(customer)
                subscription.with_plan_code(plan_code)
                moip.subscribe(subscription)
              else
                next_invoice = "#{response.next_invoice_date.day}/#{response.next_invoice_date.month}/#{response.next_invoice_date.year}"
                $.ajax
                  url: form.data('activate'),
                  type: 'PUT',
                  dataType: 'json',
                  success: (response) ->
                    window.location.href = form.data('show')
                  error: (response) ->
                    status.find('h4').html("Não foi possível ativar sua assinatura")
                    status.addClass 'failure'
                    for error in response.responseJSON.errors
                      status.find('ul').append("<li>#{error}</li>")
                    submit.show()
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
