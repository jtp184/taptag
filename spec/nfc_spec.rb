RSpec.describe 'Taptag::NFC', :hardware do
  before do
    require 'taptag/nfc'
  end

  describe '.pn_struct' do
    it 'can create a device struct' do
      expect(Taptag::NFC.send(:pn_struct)).to be_a(Taptag::PN532::PN532Struct)
    end
  end

  describe '.firmware_version' do
    it 'can get the firmware version' do
      expect(Taptag::NFC.firmware_version).to eq([1, 6, 7])
    end
  end

  describe 'interface_type' do
    after { Taptag::NFC.interface_type = nil }
    after { Taptag::NFC.remove_instance_variable(:@pn_struct) }

    context 'when not set' do
      it 'returns :spi' do
        expect(Taptag::NFC.interface_type).to eq(:spi)
      end
    end

    context 'when set to :uart' do
      before { Taptag::NFC.interface_type = :uart }
      before { allow(Taptag::PN532).to receive(:sam_configuration) }

      it 'uses uart_init for the struct' do
        allow(Taptag::PN532).to receive(:uart_init)
        expect(Taptag::PN532).to receive(:uart_init)

        Taptag::NFC.send(:pn_struct)
      end
    end

    context 'when set to :i2c' do
      before { Taptag::NFC.interface_type = :i2c }

      it 'uses i2c_init for the struct' do
        allow(Taptag::PN532).to receive(:i2c_init)
        expect(Taptag::PN532).to receive(:i2c_init)

        Taptag::NFC.send(:pn_struct)
      end
    end
  end
end
