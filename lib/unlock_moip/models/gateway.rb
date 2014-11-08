module UnlockMoip
  module Models
    module Gateway

      include UnlockGateway::Models::Gateway

      def name
        "Moip Assinaturas"
      end

      def description
        "Gerencie mensalidades, assinaturas e cobranças recorrentes com o Moip"
      end

      def image
        "unlock_moip/logo.png"
      end

      def url
        "https://moip.com.br/"
      end

      def path
        "/moip"
      end

      def available_settings
        settings = []
        instructions = "Com sua conta de negócios Moip habilitada, vá em <a href='https://www.moip.com.br/AdmMainMenuMyData.do?method=assinaturas' target='_blank'>Ferramentas › Moip Assinaturas</a> e clique em Habilitar acesso. Depois, vá em <a href='https://www.moip.com.br/AdmAPI.do?method=keys' target='_blank'>Ferramentas › API Moip › Chaves de acesso</a>."
        settings << UnlockGateway::Setting.new(:token, "Token de acesso no Moip", instructions)
        settings << UnlockGateway::Setting.new(:key, "Chave de acesso no Moip", instructions)
      end

    end
  end
end
