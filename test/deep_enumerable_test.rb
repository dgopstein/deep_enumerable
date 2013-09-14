require 'minitest/autorun'
require 'deep_enumerable.rb'
require 'set'

class TestDeepEnumerable < MiniTest::Unit::TestCase
  def test_deep_key_from_array
    f = lambda {|x| DeepEnumerable.deep_key_from_array(x)}
    #assert_equal({}, f.call([]), "empty array should make an empty ancestry hash")
    assert_equal(1, f.call([1]), "ancestry of size 1")
    assert_equal({1 => 2}, f.call([1, 2]), "ancestry of size 2")
    assert_equal({1 => {2 => 3}}, f.call([1, 2, 3]), "ancestry of size 3")
  end
end

class TestDeepHash < MiniTest::Unit::TestCase
  def test_deep_each
    hash = {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}
    all_keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    all_vals = (1..5).to_set

    assert_equal(all_keys, hash.deep_each.map(&:first).to_set, 'deep_each yields fully qualified keys of hash-only nested structures')
    assert_equal(all_vals, hash.deep_each.map(&:last).to_set, 'deep_each is implemented for hash-only nested structures')
  end
end

class TestDeepArray < MiniTest::Unit::TestCase
  def test_deep_each
    array = [1, [2, [[3], 4], 5]]
    all_keys = [0, {1 => 0}, {1 => {1 => {0 => 0}}}, {1 => {1 => 1}}, {1 => 2}].to_set
    all_vals = (1..5).to_set

    assert_equal(all_keys, array.deep_each.map(&:first).to_set, 'deep_each yields fully qualified keys for array-only nested structures')
    assert_equal(all_vals, array.deep_each.map(&:last).to_set, 'deep_each is implemented for array-only nested structures')
  end
end
