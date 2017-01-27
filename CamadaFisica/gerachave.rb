require "rbnacl"

# Dat private key
private_key = Crypto::PrivateKey.generate
# Dat public key
public_key = private_key.public_key

puts private_key
puts public_key
