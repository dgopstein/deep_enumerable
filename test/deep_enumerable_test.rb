require 'minitest/autorun'
require 'deep_enumerable.rb'
require 'set'

describe Hash do
  nested_hash = {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}

  it "should deep_dup" do
    test_deep_dup(nested_hash)
  end

  it "should deep_each" do
    keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    vals = (1..5).to_set

    test_deep_each(nested_hash, keys, vals)
  end

  it "should deep_map" do
    keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    vals = (1..5).to_set
    
    test_deep_map(nested_hash, keys, vals)
  end

  it "should deep_map_values" do
    vals = {a: {b: Fixnum, c: {d: Fixnum, e: Fixnum}, f: Fixnum}, g: Fixnum}

    test_deep_map_values(nested_hash, vals)
  end

  it "should deep_set" do
    test_deep_set(nested_hash)
  end
end

describe Array do
  nested_array = [:a, [:b, [[:c], :d], :e]]

  it "should deep_dup" do
    test_deep_dup(nested_array)
  end

  it "should deep_each" do
    keys = [0, {1 => 0}, {1 => {1 => {0 => 0}}}, {1 => {1 => 1}}, {1 => 2}].to_set
    vals = (:a..:e).to_set

    test_deep_each(nested_array, keys, vals)
  end

  it "should deep_map" do
    keys = [0, {1 => 0}, {1 => {1 => {0 => 0}}}, {1 => {1 => 1}}, {1 => 2}].to_set
    vals = (:a..:e).to_set

    test_deep_map(nested_array, keys, vals)
  end

  it "should deep_map_values" do
    vals = [Symbol, [Symbol, [[Symbol], Symbol], Symbol]] 

    test_deep_map_values(nested_array, vals)
  end

  it "should deep_set" do
    test_deep_set(nested_array)
  end
end

def test_deep_dup(de)
  copy = de.deep_dup

  copy.deep_each{|k,v| copy.deep_set(k, nil)}

  refute_equal(copy, de.deep_dup, "A deep_dup'ed copy cannot effect the original")
end

def test_deep_each(de, keys, vals)
    result_keys = Set.new
    result_vals = Set.new
    de.deep_each do |k,v|
      result_keys << k
      result_vals << v
    end
    assert_kind_of(Enumerator, de.deep_each, 'deep_each without a block returns on Enumerator')

    assert_equal(keys, result_keys, 'yields fully qualified keys')
    assert_equal(vals, result_vals, 'yields values')

    assert_equal(keys, de.deep_each.map(&:first).to_set, 'maps fully qualified keys')
    assert_equal(vals, de.deep_each.map(&:last).to_set, 'maps values')
end

def test_deep_map(de, keys, vals)
    assert_kind_of(Enumerator, de.deep_map, 'deep_map without a block returns on Enumerator')
    assert_equal(keys, de.deep_map(&:first).to_set, 'maps fully qualified keys')
    assert_equal(vals, de.deep_map(&:last).to_set, 'maps values')
end

def test_deep_map_values(de, vals)
  mapped = de.deep_map_values(&:class)
  assert_equal(de.class, mapped.class, 'deep_map_values preserves enumerable type')
  assert_equal(vals, de.map_values(&:class))
end

def test_deep_set(de)
  assert_equal(de.deep_map(&:class), de.deep_each{|k,v| de.deep_set(k, v.class)}, "deep_set'ing every element acts like mapping")
end
