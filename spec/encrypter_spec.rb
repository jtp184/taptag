require 'securerandom'

RSpec.describe Taptag::Encrypter do
  before do
    @string = SecureRandom.uuid
    @pre_key = SecureRandom.bytes(16)
    @pre_vec = SecureRandom.bytes(16)
  end

  describe 'encryption' do
    it 'can take in a string only, and return a hash of encrypted content' do
      enc = subject.encrypt(@string)

      expect(enc).to be_a(Hash)
      expect(enc).to have_key(:key)
      expect(enc).to have_key(:vector)
      expect(enc).to have_key(:data)
    end

    it 'can take in a string and key, returning randomly encoded vector' do
      enc1 = subject.encrypt(@string, key: @pre_key)
      expect(enc1[:key]).to eq(@pre_key)

      enc2 = subject.encrypt(@string, key: @pre_key)

      expect(enc1[:key]).to eq(enc2[:key])
      expect(enc1[:vector]).not_to eq(enc2[:vector])
      expect(enc1[:data]).not_to eq(enc2[:data])
    end

    it 'can take in a string, key, and vector, encoding the same value reliably' do
      enc1 = subject.encrypt(@string, key: @pre_key, vector: @pre_vec)
      expect(enc1[:key]).to eq(@pre_key)
      expect(enc1[:vector]).to eq(@pre_vec)

      enc2 = subject.encrypt(@string, key: @pre_key, vector: @pre_vec)

      expect(enc1[:key]).to eq(enc2[:key])
      expect(enc1[:vector]).to eq(enc2[:vector])
      expect(enc1[:data]).to eq(enc2[:data])
    end
  end

  describe 'decryption' do
    it 'requires data, key, and vector' do
      begin
        subject.decrypt
      rescue KeyError
        true
      end
    end

    it 'decrypts the output of #encrypt' do
      enc = subject.encrypt(@string, key: @pre_key, vector: @pre_vec)
      dec = subject.decrypt(enc)

      expect(dec).to eq(@string)
    end
  end
end
