require "moip-assinaturas"

# Configuring Moip
Moip::Assinaturas.config do |config|
  config.sandbox = true
  config.token = "NO_TOKEN_FOR_NOW"
  config.key = "NO_KEY_FOR_NOW"
end
Moip::Assinaturas::Client.default_timeout 5
