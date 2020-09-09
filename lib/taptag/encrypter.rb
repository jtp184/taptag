require 'openssl'

module Taptag
  class Encrypter
    attr_accessor :algorithm

    def initialize(algo = 'AES-128-CBC')
      @algorithm = algo
    end

    def encrypt(str)
      ec = OpenSSL::Cipher.new(algorithm)
      ec.encrypt
      key = ec.random_key
      vector = ec.random_iv

      data = ec.update(str) + ec.final

      { key: key, vector: vector, data: data }
    end

    def decrypt(args = {})
      dc = OpenSSL::Cipher.new(algorithm)
      dc.decrypt
      dc.key = args.fetch(:key)
      dc.iv = args.fetch(:vector)

      dc.update(args.fetch(:data)) + dc.final
    end
  end
end
