require_relative "../test_helper"

class TestMessagePackEncoding < Minitest::Test
  def test_default_encoding
    [nil, true, false, 10, 123456789 ** 2, 1.0, "foo", [:foo, :bar], {:a => :b}, :a].each do |data|
      assert_equal MessagePack.pack(data), ActiveSupport::MessagePack.encode(data)
    end
  end

  def test_extension_encoding
    [Time.now, /foo/, Date.new, DateTime.new].each do |data|
      assert_equal MessagePack.pack(data.as_json), ActiveSupport::MessagePack.encode(data)
    end
  end

  def test_nested_extensions
    data = {:a => { :b => :c,  :d => [:e, :f, nil]}}

    out = ActiveSupport::MessagePack.encode(data)
    assert_equal MessagePack.pack(data.as_json), out

    decoded = ActiveSupport::MessagePack.decode(out)
    expected = {"a"=>{"b"=>"c", "d"=>["e", "f", nil]}}
    assert_equal expected, decoded

  end

  def test_stringify_keys
    old = ActiveSupport.msgpack_stringify_hash_keys
    data = {1 => { 2 => :c,  :d => [:e, :f, nil]}}

    ActiveSupport.msgpack_stringify_hash_keys = false
    out = ActiveSupport::MessagePack.encode(data)
    decoded = ActiveSupport::MessagePack.decode(out)
    expected = {1=>{2=>"c", "d"=>["e", "f", nil]}}
    assert_equal expected, decoded

    ActiveSupport.msgpack_stringify_hash_keys = true
    out = ActiveSupport::MessagePack.encode(data)
    decoded = ActiveSupport::MessagePack.decode(out)
    expected_string = {"1"=>{"2"=>"c", "d"=>["e", "f", nil]}}
    assert_equal expected_string, decoded

    ActiveSupport.msgpack_stringify_hash_keys = old
  end

end
