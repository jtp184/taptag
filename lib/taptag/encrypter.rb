require 'openssl'

module Taptag
  # Handles encrypting and decrypting data using OpenSSL algorithms
  module Encrypter
    class << self
      # Takes in a string +str+ and optional +algorithm+ and returns a
      # hash with the key, vector, and encrypted data
      def encrypt(str, args = {})
        ec = OpenSSL::Cipher.new(args.fetch(:algorithm, 'AES-128-CBC'))
        ec.encrypt

        key = args.key?(:key) ? ec.key = args[:key] : ec.random_key
        vector = args.key?(:vector) ? ec.key = args[:vector] : ec.random_iv

        data = ec.update(str) + ec.final

        { key: key, vector: vector, data: data }
      end

      # Takes in +args+ for the key, vector, algorithm and data, and returns the decrypted string
      def decrypt(args = {})
        dc = OpenSSL::Cipher.new(args.fetch(:algorithm, 'AES-128-CBC'))
        dc.decrypt
        dc.key = args.fetch(:key)
        dc.iv = args.fetch(:vector)

        dc.update(args.fetch(:data)) + dc.final
      end
    end
  end
end
