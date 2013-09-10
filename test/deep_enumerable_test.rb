require 'minitest/autorun'
require 'deep_enumerable.rb'
require 'set'

class TestDeepEnumerable < MiniTest::Unit::TestCase
  def test_deep_each_on_hash
    hash = {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}
    all_keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    all_vals = (1..5).to_set

    assert_equal all_vals, hash.deep_each.map(&:last).to_set, 'deep_each is implemented for hash-only nested structures'
    assert_equal all_keys, hash.deep_each.map(&:first).to_set, 'deep_each yields fully qualified keys'
  end
end
