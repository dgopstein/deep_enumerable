require 'minitest/autorun'
require 'deep_enumerable.rb'
require 'set'

describe Hash do
  nested_hash_generator = lambda{{a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}}
  nested_hash = nested_hash_generator.call

  # TODO delete is not defined on Enumerable
  # it "should deep_delete_key" do
  #   # delete one leaf of many
  #   a = nested_hash_generator[]
  #   a.deep_delete_key({a: {b: :e}})
  #   expected = {a: {b: 1, c: {d: 2}, f: 4}, g: 5}
  #   assert_equal(expected, a)
    
  #   # delete last element in parent collection
  #   # delete non-leaf
  #   # delete non-existent key
  # end

  it "should deep_diff" do
    a = {:a => {:b => :c}}
    b = {:a => {:b => :d}}
    a_diff = {:a => {:b => :c}}
    b_diff = {:a => {:b => :d}}
    assert_equal(a_diff, a.deep_diff(b), "swapped node a->b")
    assert_equal(b_diff, b.deep_diff(a), "swapped node b->a")

    a = {:a => {:b => :c}}
    b = {:a => :b}
    a_diff = {:a => {:b => :c}}
    b_diff = {:a => :b}
    assert_equal(a_diff, a.deep_diff(b), "different values a->b")
    assert_equal(b_diff, b.deep_diff(a), "different values b->a")

    a = {:a => {:b => :c}}
    b = {:a => :b, :c => :d}
    a_diff = {:a => {:b => :c}}
    b_diff = {:a => :b, :c => :d}
    assert_equal(a_diff, a.deep_diff(b), "new key a->b")
    assert_equal(b_diff, b.deep_diff(a), "new key b->a")

    a = [0, :b, 2]
    b = {1 => :b, 2 => 3, :c => :d}
    a_diff = [0, nil, 2]
    b_diff = {2 => 3, :c => :d}
    assert_equal(a_diff, a.deep_diff(b), "array vs hash")
    assert_equal(b_diff, b.deep_diff(a), "hash vs array")

    a = [{0 => :a}]
    b = {0 => [:a]}
    a_diff = []
    b_diff = {}
    assert_equal(a_diff, a.deep_diff(b), "nested array vs hash")
    assert_equal(b_diff, b.deep_diff(a), "nested hash vs array")

    a = {:a => Hash}
    b = {:a => {1 => 2}}
    a_diff = {}
    b_diff = {:a => {1 => 2}}
    assert_equal(a_diff, a.deep_diff(b, &:===), "class equality with to_proc a->b")
    assert_equal(b_diff, b.deep_diff(a, &:===), "class equality with to_proc b->a")

    a = {:a => Array}
    b = {:a => {1 => 2}}
    a_diff = {:a => Array}
    b_diff = {:a => {1 => 2}}
    assert_equal(a_diff, a.deep_diff(b){|a,b| a === b}, "class inequality with block a->b")
    assert_equal(b_diff, b.deep_diff(a){|a,b| a === b}, "class inequality with block b->a")
  end

  it "should deep_diff_symmetric" do
    a = {:a => {:b => :c}}
    b = {:a => {:b => :d}}
    diff = {:a => {:b => [:c, :d]}}
    assert_equal(diff, a.deep_diff_symmetric(b), "swapped node")

    a = {:a => {:b => :c}}
    b = {:a => :b}
    diff = {:a => [{:b => :c}, :b]}
    assert_equal(diff, a.deep_diff_symmetric(b), "different values")

    a = {:a => {:b => :c}}
    b = {:a => :b, :c => :d}
    diff = {:a => [{:b => :c}, :b], :c => [nil, :d]}
    assert_equal(diff, a.deep_diff_symmetric(b), "new key")

    a = [0, :b, 2]
    b = {1 => :b, 2 => 3, :c => :d}
    a_diff = {0 => [0, nil], 2 => [2, 3], :c => [nil, :d]}
    b_diff = {0 => [nil, 0], 2 => [3, 2], :c => [:d, nil]}
    assert_equal(a_diff, a.deep_diff_symmetric(b), "array vs hash")
    assert_equal(b_diff, b.deep_diff_symmetric(a), "hash vs array")

    a = [{0 => :a}]
    b = {0 => [:a]}
    diff = {}
    assert_equal(diff, a.deep_diff_symmetric(b), "nested array vs hash")

    a = {:a => Hash}
    b = {:a => {1 => 2}}
    diff = {}
    assert_equal(diff, a.deep_diff_symmetric(b, &:===), "class equality with to_proc")

    a = {:a => Array}
    b = {:a => {1 => 2}}
    diff = {:a => [Array, {1 => 2}]}
    assert_equal(diff, a.deep_diff_symmetric(b){|a,b| a === b}, "class inequality with block")
  end

  it "should deep_dup" do
    test_deep_dup(nested_hash_generator)
  end

  it "should deep_each" do
    keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    vals = (1..5).to_set

    test_deep_each(nested_hash, keys, vals)
  end

  it "should deep_flat_map" do
    keys = [{:a=>:b}, {:a=>{:c=>:d}}, {:a=>{:c=>:e}}, {:a=>:f}, :g].to_set
    vals = (1..5).to_set
    
    test_deep_flat_map(nested_hash, keys, vals)
  end

  it "should deep_get" do
    test_deep_get(nested_hash, {:a => :b}, 1)
    test_deep_get(nested_hash, {:a => :c}, {d: 2, e: 3})
  end

  it "should deep_inject" do
    test_deep_inject(nested_hash)
  end

  it "should deep_intersect" do
    assert_equal({:age=>25},
                 {:name=>"alice", :age=>25}.deep_intersect(
                  :name=>"bob",   :age=>25))
  end

  it "should deep_map" do
    test_deep_map(nested_hash)
  end

  it "should deep_map_values" do
    vals = {a: {b: Fixnum, c: {d: Fixnum, e: Fixnum}, f: Fixnum}, g: Fixnum}

    test_deep_map_values(nested_hash, vals)
  end

  it "should deep_reject" do
    expected = {:a=>{:c=>{:e=>3}}, :g=>5}
    assert_equal(expected, nested_hash.deep_reject{|k, v| DeepEnumerable::leaf_key(k).to_s.ord.even?})

    expected = {:a=>{:b=>1, :c=>{:e=>3}}, :g=>5}
    assert_equal(expected, nested_hash.deep_reject(&:even?))
  end
 
  it "should deep_select" do
    expected = {a: {c: {d: 2}, f: 4}}
    assert_equal(expected, nested_hash.deep_select(&:even?))

    expected = {:a=>{:c=>{:e=>3}}, :g=>5}
    assert_equal(expected, nested_hash.deep_select{|k, v| DeepEnumerable::leaf_key(k).to_s.ord.odd?})
  end

  it "should deep_set" do
    nested_hash2 = nested_hash_generator[]
    test_deep_set(nested_hash2, {:a => :c})

    assert_equal({1=>{2=>3}}, {}.deep_set({1 => 2}, 3), 'create intermediate hashes with hash key')
    assert_equal({1=>{2=>3}}, {}.deep_set([1, 2], 3), 'create intermediate hashes with array key')

    assert_equal({1=>{2=>{3=>4}}}, {}.deep_set({1 => {2 => 3}}, 4), 'create deeper intermediate hashes with hash key')
    assert_equal({1=>{2=>{3=>4}}}, {}.deep_set([1, 2, 3], 4), 'create deeper intermediate hashes with array key')

    assert_equal({1=>{2=>{3=>4}}},         {1 => 2}.deep_set({1 => {2 => 3}}, 4), 'create deeper intermediate hashes with hash key and branch collision')
    assert_equal({1=>{2=>{3=>4}}},         {1 => {2 => 3}}.deep_set([1, 2, 3], 4), 'create deeper intermediate hashes with array key and leaf collision')
    assert_equal({1=>{2=>{3=>4}, 3 => 2}}, {1 => {3 => 2}}.deep_set([1, 2, 3], 4), 'create deeper intermediate hashes with array key and leaf collision')

    assert_equal({1=>2}, {}.deep_set([1], 2), 'set using a singular key')
  end

  it "should deep_values" do
    vals = [1, 2, 3, 4, 5]

    test_deep_values(nested_hash, vals)
  end

  it "should deep_zip" do
    test_deep_zip(nested_hash) {|x| x*2}

    a = {a: 1, c: 3}
    b = {b: 2, d: 4}
    c = {c: 1, d: 4}
    expected_ab = {a: [1, nil], c: [3, nil]}
    expected_ac = {a: [1, nil], c: [3, 1]}
    assert_equal(expected_ab, a.deep_zip(b))
    assert_equal(expected_ac, a.deep_zip(c))
  end

  it "should shallow_each" do
    expected = [[:a, {:b=>1, :c=>{:d=>2, :e=>3}, :f=>4}], [:g, 5]]
    assert_equal(expected, nested_hash.shallow_each.to_a)

    res = []
    nested_hash.shallow_each{|k, v| res << [k, v]}
    assert_equal(expected, res)

    res = nested_hash.shallow_each{|k, v| nil}
    assert_equal(expected, res)
  end

  it "should shallow_map_keys" do
    upper_keys = {A: {b: 1, c: {d: 2, e: 3}, f: 4}, G: 5}
    class_keys = {Hash => {b: 1, c: {d: 2, e: 3}, f: 4}, Fixnum => 5}

    assert_equal(upper_keys, nested_hash.shallow_map_keys(&:upcase))

    # test the two-arg version
    assert_equal(class_keys, nested_hash.shallow_map_keys{|_, v| v.class})
  end

  it "should shallow_map_values" do
    vals = {a: Hash, g: Fixnum}

    test_shallow_map_values(nested_hash, vals)

    # test the two-arg version
    assert_equal(vals,                   nested_hash.shallow_map_values{|_, v| v.class}) 
    assert_equal({a: Symbol, g: Symbol}, nested_hash.shallow_map_values{|k, _| k.class}) 
  end
end

describe Array do
  nested_array_generator = lambda{[:a, [:b, [[:c], :d], :e]]}
  nested_array = nested_array_generator[]

  # TODO delete is not defined on Enumerable
  # it "should deep_delete_key" do
  #   # delete one leaf of many
  #   a = nested_array_generator[]
  #   a.deep_delete_key({1 => 1})
  #   expected = [:a, [:b, :d], :e]
  #   assert_equal(expected, a)
    
  #   # delete last element in parent collection
  #   # delete non-leaf
  #   # delete non-existent key
  # end

  it "should deep_diff" do
    a = [{a: 1, b: 2}, {c: 3, d: 4}]
    b = [{a: 1, b: 2}, {c: 3, d: 5}]
    a_diff = [nil, {d: 4}]
    b_diff = [nil, {d: 5}]

    assert(a_diff, a.deep_diff(b))
    assert(b_diff, b.deep_diff(a))
  end

  it "should deep_diff_symmetric" do
    a = [{a: 1, b: 2}, {c: 3, d: 4}]
    b = [{a: 1, b: 2}, {c: 3, d: 5}]
    a_diff = {1 => {d: [4, 5]}}
    b_diff = {1 => {d: [5, 4]}}

    assert(a_diff, a.deep_diff_symmetric(b))
    assert(b_diff, a.deep_diff_symmetric(a))
  end

  it "should deep_dup" do
    test_deep_dup(nested_array_generator)
  end

  it "should deep_each" do
    keys = [0, {1 => 0}, {1 => {1 => {0 => 0}}}, {1 => {1 => 1}}, {1 => 2}].to_set
    vals = (:a..:e).to_set

    test_deep_each(nested_array, keys, vals)
  end

  it "should deep_flat_map" do
    keys = [0, {1 => 0}, {1 => {1 => {0 => 0}}}, {1 => {1 => 1}}, {1 => 2}].to_set
    vals = (:a..:e).to_set

    test_deep_flat_map(nested_array, keys, vals)
  end

  it "should deep_get" do
    test_deep_get(nested_array, {1 => 0}, :b)
    test_deep_get(nested_array, {1 => 1}, [[:c], :d])
  end

  it "should deep_inject" do
    test_deep_inject(nested_array)
  end

  it "should deep_intersect" do
    bob = {:friends=>["alice","carol"]}
    carol = {:friends=>["alice","bob"]}
    assert_equal({:friends=>["alice"]}, bob.deep_intersect(carol))
  end

  it "should deep_map" do
    test_deep_map(nested_array)
  end

  it "should deep_map_values" do
    vals = [Symbol, [Symbol, [[Symbol], Symbol], Symbol]] 

    test_deep_map_values(nested_array, vals)
  end

  it "should deep_select" do
    expected = [[:b, [[], :d]]]
    assert_equal(expected, nested_array.deep_select{|sym| sym.to_s.ord.even?})

    shallow_a = [2, 3, 4]
    assert_equal(shallow_a.select(&:even?), shallow_a.deep_select(&:even?))
    assert_equal(shallow_a.select{|k,v| k.odd?}, shallow_a.deep_select{|k,v| k.odd?})

    assert_equal([[2, 4], 6] , [1, shallow_a, 6].deep_select(&:even?))
  end

  it "should deep_set" do
    nested_array2 = nested_array_generator[]
    test_deep_set(nested_array2, {1 => 1})
  
    assert_equal([nil, [nil, nil, 3]], [].deep_set({1 => 2}, 3), 'create intermediate arrays')
    assert_equal([nil, [nil, nil, 3]], [].deep_set([1, 2], 3), 'create intermediate hashes with array key')

    assert_equal([nil, [nil, nil, [nil, nil, nil, 4]]],
      [nil, [nil, nil, 3]].deep_set({1 => {2 => 3}}, 4), 'create deeper intermediate hashes with hash key and branch collision')
    assert_equal([nil, [nil, nil, [nil, nil, nil, 4]]],
      [nil, [nil, nil, [nil, nil, nil, 4]]].deep_set([1, 2, 3], 4), 'create deeper intermediate hashes with array key and leaf collision')
    assert_equal([nil, [nil, nil, [nil, nil, nil, 4, 5]]],
      [nil, [nil, nil, [nil, nil, nil, 3, 5]]].deep_set([1, 2, 3], 4), 'create deeper intermediate hashes with array key and leaf collision')

    assert_equal([nil, 2], [].deep_set([1], 2), 'set using a singular key')
  end

  it "should deep_values" do
    vals = [:a, :b, :c, :d, :e]

    test_deep_values(nested_array, vals)
  end

  it "should deep_zip" do
    test_deep_zip(nested_array, &:upcase)

    a = [0, 1]
    b = [2]
    c = [3, 4, 5]
    expected_ab = [[0, 2], [1, nil]]
    expected_ac = [[0, 3], [1, 4]]
    assert_equal(expected_ab, a.deep_zip(b))
    assert_equal(expected_ac, a.deep_zip(c))
  end

  it "should shallow_each" do
    expected = [[0, :a], [1, [:b, [[:c], :d], :e]]]
    assert_equal(expected, nested_array.shallow_each.to_a)

    res = []
    nested_array.shallow_each{|k, v| res << [k, v]}
    assert_equal(expected, res)

    res = nested_array.shallow_each{|k, v| nil}
    assert_equal(expected, res)
  end

  it "should shallow_map_keys" do
    array = [2, 3, 3, 1, 0, 5]
    every_other = [2, nil, 3, nil, 3, nil, 1, nil, 0, nil, 5]
    by_value = [0, 1, 2, 3, nil, 5]

    assert_equal(every_other, array.shallow_map_keys{|k| k*2})
    assert_equal(by_value, array.shallow_map_keys{|_, v| v})
  end

  it "should shallow_map_values" do
    vals = [Symbol, Array] 

    test_shallow_map_values(nested_array, vals)

    # test the two-arg version
    assert_equal(vals,             nested_array.shallow_map_values{|_, v| v.class}) 
    assert_equal([Fixnum, Fixnum], nested_array.shallow_map_values{|k, _| k.class}) 
  end
end

describe "Helper Functions" do
  it "should deep_key_to_array" do
    assert_equal(['a'], DeepEnumerable::deep_key_to_array('a'))
    assert_equal([:a], DeepEnumerable::deep_key_to_array(:a))
    assert_equal([1], DeepEnumerable::deep_key_to_array(1))

    assert_equal(['a'], DeepEnumerable::deep_key_to_array(['a']))
    assert_equal([:a], DeepEnumerable::deep_key_to_array([:a]))
    assert_equal([1], DeepEnumerable::deep_key_to_array([1]))

    assert_equal(['b', 'a'], DeepEnumerable::deep_key_to_array({'b' => 'a'}))
    assert_equal([:b, :a], DeepEnumerable::deep_key_to_array({:b => :a}))
    assert_equal([2, 1], DeepEnumerable::deep_key_to_array({2 => 1}))

    assert_equal(['c', 'b', 'a'], DeepEnumerable::deep_key_to_array({'c' => {'b' => 'a'}}))
    assert_equal([:c, :b, :a], DeepEnumerable::deep_key_to_array({:c => {:b => :a}}))
    assert_equal([3, 2, 1], DeepEnumerable::deep_key_to_array({3 => {2 => 1}}))
  end

  it "should leaf_key" do
    assert_equal('a', DeepEnumerable::leaf_key('a'))
    assert_equal(:a, DeepEnumerable::leaf_key(:a))
    assert_equal(1, DeepEnumerable::leaf_key(1))

    assert_equal('a', DeepEnumerable::leaf_key({'b' => 'a'}))
    assert_equal(:a, DeepEnumerable::leaf_key({:b => :a}))
    assert_equal(1, DeepEnumerable::leaf_key({2 => 1}))

    assert_equal('a', DeepEnumerable::leaf_key({'c' => {'b' => 'a'}}))
    assert_equal(:a, DeepEnumerable::leaf_key({:c => {:b => :a}}))
    assert_equal(1, DeepEnumerable::leaf_key({3 => {2 => 1}}))
  end

  it "should split_key" do
    assert_equal([:a, {0 => :a}], DeepEnumerable::split_key({a: {0 => :a}}))
    assert_equal([0, :a], DeepEnumerable::split_key({0 => :a}))
    assert_equal([:a, [0, :a]], DeepEnumerable::split_key([:a, 0, :a]))
    assert_equal([0, [:a]], DeepEnumerable::split_key([0, :a]))
    assert_equal([:a, nil], DeepEnumerable::split_key([:a]))
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

def test_deep_flat_map(de, keys, vals)
    assert_equal(keys, de.deep_flat_map(&:first).to_set, 'maps fully qualified keys')
    assert_equal(vals, de.deep_flat_map(&:last).to_set, 'maps values')
    assert_equal(keys.zip(vals).flatten, de.deep_flat_map{|a, b| [a, b]}, 'maps keys and values')
end

def test_deep_get(de, key, val)
  first_key = key.keys.first
  assert_equal(de[first_key], de.deep_get(first_key), "deep_get gets shallow values (at a non-leaf)")
  assert_equal(val, de.deep_get(key), "deep_get gets nested values (at a leaf)")
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

  singular_key = [7]
  dc.deep_set(singular_key, 45)
  assert_equal(45, dc.deep_get(singular_key[0]))
end

def test_deep_values(de, values)
  assert_equal(values, de.deep_values, 'returns leaf values')
end

def test_deep_zip(de, &block)
  h1 = de
  h2 = de.deep_map_values{|x| block.call(x)}
  expected = h1.deep_map_values{|x| [x, block.call(x)]}
  assert_equal(expected, h1.deep_zip(h2))
  
  # throw out first item
  h1_2 = h1.reject{|k, v| k == h1.shallow_keys.last}
  h2_2 = h2.reject{|k, v| k == h2.shallow_keys.last}
  expected_1 = h1_2.deep_map_values{|v| [v, block.call(v)]}
  expected_2 = h1.deep_map_values{|v| [v, if v == h1[h1.shallow_keys.last] || v.nil? then nil else block.call(v) end]}
  assert_equal(expected_1, h1_2.deep_zip(h2))
  assert_equal(expected_2, h1.deep_zip(h2_2))
end

def test_shallow_map_values(de, vals)
  mapped = de.shallow_map_values(&:class)
  assert_equal(de.class, mapped.class, 'deep_map_values preserves enumerable type')
  assert_equal(vals, mapped)
end
