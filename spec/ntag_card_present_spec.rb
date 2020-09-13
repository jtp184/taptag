RSpec.describe 'When ntag card is Present', :hardware, :ntag do
  before do
    require 'taptag/nfc'
  end

  it 'can get a card uid' do
    u = Taptag::NFC.card_uid
    expect(u.is_a?(Array)).to be(true)
  end

  it 'can get the type of card from uid length' do
    u = Taptag::NFC.card_format

    expect(u).to be_a(Symbol)
    expect(u).to eq(:ntag)
  end

  it 'can read ntag blocks' do
    c = Taptag::NFC.read_ntag_block(100)

    expect(c).to be_a(Array)
    expect(c.length).to be(4)
  end

  it 'can read entire ntag cards' do
    c = Taptag::NFC.read_ntag_card

    expect(c).to be_a(Array)
    expect(c.length).to be(Taptag::PN532::NTAG2XX_BLOCK_COUNT)

    expect(c[0][0]).to be(0)

    expect(c[0][1]).to be_a(Array)
    expect(c[0][1].length).to be(Taptag::PN532::NTAG2XX_BLOCK_LENGTH)
  end

  it 'can write a single block' do
    Taptag::NFC.write_ntag_block(6, Array.new(4, 128))

    expect(Taptag::NFC.read_ntag_block(6)).to eq(Array.new(4, 128))
  end

  it 'can write multiple blocks' do
    blks = [
      [5, Array.new(4, 64)],
      [6, Array.new(4, 128)]
    ]

    Taptag::NFC.write_mifare_card(blks)

    expect(Taptag::NFC.read_mifare_card([5, 6])).to eq(blks)
  end
end
