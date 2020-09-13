RSpec.describe 'Taptag::NFC', :hardware do
  before do
    require 'taptag/nfc'
  end

  it 'can create a device struct' do
    expect(Taptag::NFC.send(:pn_struct)).to be_a(Taptag::PN532::PN532Struct)
  end

  it 'can get the firmware version' do
    expect(Taptag::NFC.firmware_version).to eq([1, 6, 7])
  end
end
