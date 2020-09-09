RSpec.describe Taptag::NFC, :hardware do
  it 'can create a device struct' do
    expect(subject.send(:pn_struct)).to be_a(Taptag::PN532::PN532Struct)
  end
end
