require 'minitest/autorun'
require 'deep_enumerable.rb'
require 'set'

describe Hash do
  it "should work with :deep_each" do
    hash = {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}
    keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    vals = (1..5).to_set

    test_deep_each(hash, keys, vals)
  end
end

describe Array do
  it "should work with DeepEnumerable" do
    array = [:a, [:b, [[:c], :d], :e]]
    keys = [0, {1 => 0}, {1 => {1 => {0 => 0}}}, {1 => {1 => 1}}, {1 => 2}].to_set
    vals = (:a..:e).to_set

    test_deep_each(array, keys, vals)
  end
end

def test_deep_each(object, keys, vals)
    result_keys = Set.new
    result_vals = Set.new
    object.deep_each do |k,v|
      result_keys << k
      result_vals << v
    end
    assert_equal(keys, result_keys, 'yields fully qualified keys')
    assert_equal(vals, result_vals, 'yields values')

    assert_equal(keys, object.deep_each.map(&:first).to_set, 'maps fully qualified keys')
    assert_equal(vals, object.deep_each.map(&:last).to_set, 'maps values')
end
