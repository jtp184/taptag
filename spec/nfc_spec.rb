RSpec.describe 'Taptag::NFC', :hardware do
  before do
    require 'taptag/nfc'
  end

  it 'can create a device struct' do
    expect(Taptag::NFC.send(:pn_struct)).to be_a(Taptag::PN532::PN532Struct)
  end
end
