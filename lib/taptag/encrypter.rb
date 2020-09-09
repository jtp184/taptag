require 'openssl'

module Taptag
  # Handles encrypting and decrypting data using OpenSSL algorithms
  class Encrypter
    # String used to instantiate the Cipher instance
    attr_accessor :algorithm

    # Uses the +algo+ provided, or 'AES-128-CBC' by default
    def initialize(algo = 'AES-128-CBC')
      @algorithm = algo
    end

    # Takes in a string +str+ and returns a hash with the key, vector, and encrypted data
    def encrypt(str)
      ec = OpenSSL::Cipher.new(algorithm)
      ec.encrypt
      key = ec.random_key
      vector = ec.random_iv

      data = ec.update(str) + ec.final

      { key: key, vector: vector, data: data }
    end

    # Takes in +args+ for the key, vector, and data, and returns the decrypted string
    def decrypt(args = {})
      dc = OpenSSL::Cipher.new(algorithm)
      dc.decrypt
      dc.key = args.fetch(:key)
      dc.iv = args.fetch(:vector)

      dc.update(args.fetch(:data)) + dc.final
    end
  end
end
