require 'securerandom'

RSpec.describe Taptag::Encoder do
  before do
    @string = SecureRandom.uuid
    @string_arry = [
      [0, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]],
      [1, [72, 111, 114, 107, 45, 66, 97, 106, 105, 114, 32, 67, 104, 114, 111, 110]],
      [2, [105, 99, 108, 101, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]],
      [3, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]
    ]
  end

  it 'can take a string and encode it into ordenals' do
    str = 'Yeerk'
    arry = [89, 101, 101, 114, 107]

    expect(subject.encode_string(str)).to eq(arry)
  end

  it 'can take an array of bytes and decode it into a string' do
    arry = [74, 97, 107, 101]
    str = 'Jake'

    expect(subject.decode_string(arry)).to eq(str)
  end

  it 'can slice an array of bytes into frames' do
    row_siz = 4
    str = 'Tobias'

    frames = subject.slice_string(
      subject.encode_string(str),
      row_siz
    )

    expect(frames.length).to be(2)
    expect(frames.last.last(2)).to eq([0, 0])
    expect(frames.map(&:length).all?(row_siz)).to be(true)
  end

  it 'can zip blocks by index' do
    str = Array.new(25) { SecureRandom.alphanumeric }.join
    str = subject.encode_string(str)
    str = subject.slice_string(str, 4)

    blks = subject.zip_blocks(str, (0..1000).select(&:odd?))

    expect(blks[0][0]).to be(1)
    expect(blks[1][0]).to be(3)

    expect(blks.map(&:last)).to eq(str)
  end

  it 'can zip blocks by mifare blocks by default' do
    str = Array.new(25) { SecureRandom.alphanumeric }.join
    str = subject.encode_string(str)
    str = subject.slice_string(str, 16)

    blks = subject.zip_blocks(str)

    expect(blks.map(&:first)).to eq(subject.writable_mifare_blocks.first(blks.length))
  end

  it 'can reduce blocks' do
    str = @string_arry

    blks = subject.reduce_blocks(str)

    expect(blks).to be_a(Array)
    expect(blks).to eq(blks.flatten)
    expect(blks.map(&:chr).join.gsub(/#{0.chr}+/, '')).to eq('Hork-Bajir Chronicles')
  end

  it 'can automatically detect arguments' do
    ex0 = subject['Rachel']
    ex1 = subject.call(subject.encode_string('Marco'))
    ex2 = subject.(ex0)

    expect(ex0).to be_a(Array)
    expect(ex0[0][0]).to be(1)
    expect(ex0[0][1][0]).to be(82)

    expect(ex1).to be_a(Array)
    expect(ex1.all? { |x| x.is_a?(Array) }).to be(true)
    expect(ex1[-1][-1]).to be(0)

    expect(ex2).to be_a(String)
    expect(ex2).to eq('Rachel')
  end

  it 'can reduce blocks without indexes' do
    str = @string_arry

    blks = subject.reduce_blocks(str.map(&:last))

    expect(blks).to be_a(Array)
    expect(blks).to eq(blks.flatten)
    expect(blks.map(&:chr).join.gsub(/#{0.chr}+/, '')).to eq('Hork-Bajir Chronicles')
  end

  it 'can create blank blocks' do
    blks = subject.blank_blocks

    expect(blks).to be_a(Array)
    expect(blks.map(&:first)).to eq(subject.writable_mifare_blocks)
    expect(blks.map(&:last).flatten.uniq).to eq([0])
  end

  it 'can create repeated frames' do
    blks = subject.blank_blocks(subject.writable_mifare_blocks, Array.new(16, 255))

    expect(blks).to be_a(Array)
    expect(blks.map(&:first)).to eq(subject.writable_mifare_blocks)
    expect(blks.map(&:last).flatten.uniq).to eq([255])
  end

  it 'can take in symbolic arguments for tag types' do
    blks0 = subject['Cassie', :ntag]

    expect(blks0.map(&:last).map(&:length)).to eq([4, 4])

    blks1 = subject['Cassie', :mifare]

    expect(blks1.map(&:last).map(&:length)).to eq([16])
  end
end
