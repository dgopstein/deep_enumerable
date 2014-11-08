require 'minitest/autorun'
require 'deep_enumerable.rb'
require 'set'

describe Hash do
  nested_hash_generator = lambda{{a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}}
  nested_hash = nested_hash_generator.call

  it "should deep_dup" do
    test_deep_dup(nested_hash_generator)
  end

  it "should deep_diff" do
    a = {:a => {:b => :c}}
    b = {:a => {:b => :d}}
    diff = {:a => {:b => [:c, :d]}}
    assert_equal(diff, a.deep_diff(b), "swapped node")

    a = {:a => {:b => :c}}
    b = {:a => :b}
    diff = {:a => [{:b => :c}, :b]}
    assert_equal(diff, a.deep_diff(b), "different values")

    a = {:a => {:b => :c}}
    b = {:a => :b, :c => :d}
    diff = {:a => [{:b => :c}, :b], :c => [nil, :d]}
    assert_equal(diff, a.deep_diff(b), "new key")

    a = [0, :b, 2]
    b = {1 => :b, :c => :d}
    diff = {0 => [0, nil], 2 => [2, nil], :c => [nil, :d]}
    assert_equal(diff, a.deep_diff(b), "array vs hash")

    a = [{0 => :a}]
    b = {0 => [:a]}
    diff = {}
    assert_equal(diff, a.deep_diff(b), "nested array vs hash")

    a = {:a => Hash}
    b = {:a => {1 => 2}}
    diff = {}
    assert_equal(diff, a.deep_diff(b, &:===), "class equality with to_proc")

    a = {:a => Array}
    b = {:a => {1 => 2}}
    diff = {:a => [Array, {1 => 2}]}
    assert_equal(diff, a.deep_diff(b){|a,b| a === b}, "class inequality with block")
  end

  it "should deep_each" do
    keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    vals = (1..5).to_set

    test_deep_each(nested_hash, keys, vals)
  end

  it "should deep_map" do
    test_deep_map(nested_hash)
  end

  it "should deep_inject" do
    test_deep_inject(nested_hash)
  end

  it "should deep_flat_map" do
    keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    vals = (1..5).to_set
    
    test_deep_flat_map(nested_hash, keys, vals)
  end

  it "should deep_values" do
    vals = [1, 2, 3, 4, 5]

    test_deep_values(nested_hash, vals)
  end

  it "should map_keys" do
    upper_keys = {A: {b: 1, c: {d: 2, e: 3}, f: 4}, G: 5}
    class_keys = {Hash => {b: 1, c: {d: 2, e: 3}, f: 4}, Fixnum => 5}

    assert_equal(upper_keys, nested_hash.map_keys(&:upcase))

    # test the two-arg version
    assert_equal(class_keys, nested_hash.map_keys{|_, v| v.class})
  end

  it "should map_values" do
    vals = {a: Hash, g: Fixnum}

    test_map_values(nested_hash, vals)

    # test the two-arg version
    assert_equal(vals,                   nested_hash.map_values{|_, v| v.class}) 
    assert_equal({a: Symbol, g: Symbol}, nested_hash.map_values{|k, _| k.class}) 
  end

  it "should deep_map_values" do
    vals = {a: {b: Fixnum, c: {d: Fixnum, e: Fixnum}, f: Fixnum}, g: Fixnum}

    test_deep_map_values(nested_hash, vals)
  end

  it "should deep_set" do
    nested_hash2 = {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}
    test_deep_set(nested_hash2, {:a => :c})
  end

  it "should deep_get" do
    test_deep_get(nested_hash, {:a => :b}, 1)
  end
end

describe Array do
  nested_array_generator = lambda{[:a, [:b, [[:c], :d], :e]]}
  nested_array = nested_array_generator[]

  it "should deep_dup" do
    test_deep_dup(nested_array_generator)
  end

  it "should deep_each" do
    keys = [0, {1 => 0}, {1 => {1 => {0 => 0}}}, {1 => {1 => 1}}, {1 => 2}].to_set
    vals = (:a..:e).to_set

    test_deep_each(nested_array, keys, vals)
  end

  it "should deep_map" do
    test_deep_map(nested_array)
  end

  it "should deep_inject" do
    test_deep_inject(nested_array)
  end

  it "should deep_flat_map" do
    keys = [0, {1 => 0}, {1 => {1 => {0 => 0}}}, {1 => {1 => 1}}, {1 => 2}].to_set
    vals = (:a..:e).to_set

    test_deep_flat_map(nested_array, keys, vals)
  end

  it "should deep_values" do
    vals = [:a, :b, :c, :d, :e]

    test_deep_values(nested_array, vals)
  end

  it "should map_keys" do
    array = [2, 3, 1, 0, 5]
    every_other = [2, nil, 3, nil, 1, nil, 0, nil, 5]
    by_value = [0, 1, 2, 3, nil, 5]

    assert_equal(every_other, array.map_keys{|k| k*2})
    assert_equal(by_value, array.map_keys{|_, v| v})
  end

  it "should map_values" do
    vals = [Symbol, Array] 

    test_map_values(nested_array, vals)

    # test the two-arg version
    assert_equal(vals,             nested_array.map_values{|_, v| v.class}) 
    assert_equal([Fixnum, Fixnum], nested_array.map_values{|k, _| k.class}) 
  end

  it "should deep_map_values" do
    vals = [Symbol, [Symbol, [[Symbol], Symbol], Symbol]] 

    test_deep_map_values(nested_array, vals)
  end

  it "should deep_set" do
    nested_array2 = [:a, [:b, [[:c], :d], :e]]
    test_deep_set(nested_array2, {1 => 1})
  end

  it "should deep_get" do
    test_deep_get(nested_array, {1 => 0}, :b)
  end
end

def test_deep_dup(de_generator)
  de = de_generator.call
  untouched = de_generator.call

  assert_equal(de, untouched, "An untouched deep_dup'd enumerable matches the original")

  mutated_copy = de.deep_dup
  mutated_copy.deep_each{|k,v| mutated_copy.deep_set(k, nil)}

  refute_equal(mutated_copy, de, "A deep_dup'd copy cannot effect the original")
  assert_equal(untouched, de, "An untouched deep_dup'd enumerable matches the original, even after other stuff is mutated")
  assert_equal(untouched.class, de.class, "A deep_dup'd copy should be the same class as the original")
  assert_equal(untouched.to_a, de.to_a, "A deep_dup'd copy should have the same elements as the original")
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

def test_deep_inject(de)
    expected = "test: "+de.deep_values.join
    sum = de.deep_inject("test: ") {|str, (k, v)| str+v.to_s}
    assert_equal(expected, sum, 'injects all values into argument string')
end

def test_deep_map(de)
    assert_kind_of(Enumerator, de.deep_map, 'deep_map without a block returns on Enumerator')
    assert_equal(de.class, de.deep_map{|x| x}.class, 'deep_map_values preserves enumerable type')
    orig = de.deep_dup
    de.deep_map{|x, y| y.class}
    assert_equal(orig, de, "deep_map does not mutate the DeepEnumerable")

    mapped = de.deep_map{|k,v| v.class}
    all_the_same = true
    de.deep_each{|k,v| all_the_same &&= (v.class == mapped.deep_get(k))}
    assert(all_the_same, "deep_map maps over all the elements deep_each hits")
end

def test_deep_flat_map(de, keys, vals)
    assert_equal(keys, de.deep_flat_map(&:first).to_set, 'maps fully qualified keys')
    assert_equal(vals, de.deep_flat_map(&:last).to_set, 'maps values')
end

def test_deep_values(de, values)
  assert_equal(values, de.deep_values, 'returns leaf values')
end

def test_map_values(de, vals)
  mapped = de.map_values(&:class)
  assert_equal(de.class, mapped.class, 'deep_map_values preserves enumerable type')
  assert_equal(vals, mapped)
end

def test_deep_map_values(de, vals)
  mapped = de.deep_map_values(&:class)
  assert_equal(de.class, mapped.class, 'deep_map_values preserves enumerable type')
  assert_equal(vals, mapped)
end

def test_deep_set(de, key)
  dc = de.deep_dup
  dc.deep_set(key, 42)
  assert_equal(42, dc.deep_get(key), "deep_set sets deep values")

  dc.deep_set(key.keys.first, 43)
  assert_equal(43, dc.deep_get(key.keys.first), "deep_set sets shallow values")

  non_existant_key = {1 => {2 => 3}}
  dc.deep_set(non_existant_key, 44)
  assert_equal(44, dc.deep_get(non_existant_key))
end

def test_deep_get(de, key, val)
  first_key = key.keys.first
  assert_equal(de[first_key], de.deep_get(first_key), "deep_get gets shallow values (at a non-leaf)")
  assert_equal(val, de.deep_get(key), "deep_get gets nested values (at a leaf)")
end
