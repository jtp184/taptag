RSpec.describe 'When mifare card is Present', :hardware, :mifare do
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
    expect(u == :mifare || u == :ntag).to be(true)
  end

  it 'can authorize mifare blocks' do
    a = Taptag::NFC.auth_mifare_block(6)
    expect(a).to eq(0)
  end

  it 'can read mifare blocks' do
    c = Taptag::NFC.read_mifare_block(6)

    expect(c).to be_a(Array)
    expect(c.length).to be(16)
  end

  it 'can read entire mifare cards' do
    c = Taptag::NFC.read_mifare_card

    expect(c).to be_a(Array)
    expect(c.length).to be(64)

    expect(c[0][0]).to be(0)

    expect(c[0][1]).to be_a(Array)
    expect(c[0][1].length).to be(16)
  end

  it 'can write a single block' do
    Taptag::NFC.write_mifare_block(6, Array.new(16, 128))

    expect(Taptag::NFC.read_mifare_block(6)).to eq(Array.new(16, 128))
  end

  it 'can write multiple blocks' do
    blks = [
      [5, Array.new(16, 64)],
      [6, Array.new(16, 128)]
    ]

    Taptag::NFC.write_mifare_card(blks)

    expect(Taptag::NFC.read_mifare_card([5, 6])).to eq(blks)
  end
end
