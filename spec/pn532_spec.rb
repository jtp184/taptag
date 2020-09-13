RSpec.describe 'Taptag::PN532', :hardware do
  before do
    require 'taptag/pn532/library_constants'
    require 'taptag/pn532/structs'
    require 'taptag/pn532/pn532'
  end

  %i[
    read_passive_target
    sam_configuration
    get_firmware_version
    mifare_authenticate_block
    mifare_read_block
    mifare_write_block
  ].map do |sig|
    it "implements #{sig}" do
      raise NoMethodError unless Taptag::PN532.respond_to?(sig)
    end
  end

  it 'provides access to its library constants' do
    expect(Taptag::PN532.lib_constants).to be_a(Hash)
  end

  describe 'structs' do
    it 'can create device structs' do
      d_struct = Taptag::PN532::PN532Struct.new
      expect(d_struct).not_to be_nil
    end

    describe 'DataBuffer' do
      it 'can create blank databuffers' do
        d = Taptag::PN532::DataBuffer.new
        expect(d).not_to be_nil
        expect(d.to_a).to be_a(Array)
      end

      it 'can set databuffers to known values' do
        rand_data = Array.new(255) { rand(255) }
        d = Taptag::PN532::DataBuffer.new.set(rand_data)

        random_checks = (0..255).to_a.sample(12)

        random_checks.each do |rc|
          expect(d[rc]).to eq(rand_data[rc])
        end
      end

      it 'can blank databuffers' do
        d = Taptag::PN532::DataBuffer.new.set(Array.new(255) { rand(255) })
        d.reset
        expect(d.to_a.all?(0)).to be(true)
      end

      it 'can return just the nonzero length of a buffer' do
        d = Taptag::PN532::DataBuffer.new.set(Array.new(128, 255))
        expect(d.nonzero_length).to eq(128)
      end
    end
  end
end
