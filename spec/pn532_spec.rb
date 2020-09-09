RSpec.describe Taptag::PN532 do
  it 'extends FFI' do
  end

  [
    :read_passive_target,
    :sam_configuration,
    :get_firmware_version,
    :mifare_authenticate_block,
    :mifare_read_block,
    :mifare_write_block
  ].map do |sig|
    it "implements #{sig}" do
      raise NoMethodError unless subject.respond_to?(sig)
    end
  end

end
