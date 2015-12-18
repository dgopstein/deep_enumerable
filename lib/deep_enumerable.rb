##
# A set of general methods that can be applied to any conformant nested structure
module DeepEnumerable
  ##
  # Subtracts the leaves of one DeepEnumerable from another.
  #
  # @return a result of the same structure as the primary DeepEnumerable.
  #
  # @example
  #  >> alice = {name: "alice", age: 26}
  #  >> bob   = {name: "bob",   age: 26}
  #  >> alice.deep_diff(bob)
  #  => {:name=>"alice"}
  #
  #  >> bob   = {friends: ["alice","carol"]}
  #  >> carol = {friends: ["alice","bob"]}
  #  >> bob.deep_diff(carol)
  #  => {:friends=>"carol"}
  #
  def deep_diff(other, &block)
    shallow_keys.each_with_object(empty) do |key, res|
      s_val = (self[key] rescue nil) #TODO don't rely on rescue
      o_val = (other[key] rescue nil)

      comparator = block || :==.to_proc

      if s_val.respond_to?(:deep_diff) && o_val.respond_to?(:deep_diff)
        diff = s_val.deep_diff(o_val, &block)
        res[key] = diff if diff.any?
      elsif !comparator.call(s_val, o_val)
        res[key] = s_val
      end
    end
  end
  
  ##
  # Computes the complement of the intersection of two DeepEnumerables.
  #
  # @return The common structure of both arguments, with tuples containing differing values in the leaf nodes.
  #
  # @example
  #  >> alice = {:name=>"alice", :age=>26}
  #  >> bob   = {:name=>"bob",   :age=>26}
  #  >> alice.deep_diff_symmetric(bob)
  #  => {:name=>["alice", "bob"]}
  #
  #  >> bob   = {:friends=>["alice","carol"]}
  #  >> carol = {:friends=>["alice","bob"]}
  #  >> bob.deep_diff_symmetric(carol)
  #  => {:friends=>{1=>["carol", "bob"]}}
  #
  def deep_diff_symmetric(other, &block)
    (shallow_keys + other.shallow_keys).each_with_object({}) do |key, res|
      s_val = (self[key] rescue nil) #TODO don't rely on rescue
      o_val = (other[key] rescue nil)

      comparator = block || :==.to_proc

      if s_val.respond_to?(:deep_diff_symmetric) && o_val.respond_to?(:deep_diff_symmetric)
        diff = s_val.deep_diff_symmetric(o_val, &block)
        res[key] = diff if diff.any?
      elsif !comparator.call(s_val, o_val)
        res[key] = [s_val, o_val]
      end
    end
  end
  alias_method :deep_outersect, :deep_diff_symmetric

  ##
  # Deeply copy a DeepEnumerable
  #
  # @return the same data structure at a different memory address
  def deep_dup
    deep_select{true}
  end

  ##
  # Iterate elements of a DeepEnumerable
  #
  # @example
  #   >> {event: {id: 1, title: 'bowling'}}.deep_each.to_a
  #   => [[{:event=>:id}, 1], [{:event=>:title}, "bowling"]]
  # 
  #   >> [:a, [:b, :c]].deep_each.to_a
  #   => [[0, :a], [{1=>0}, :b], [{1=>1}, :c]]
  #
  #   >> {events: [{title: 'movie'}, {title: 'dinner'}]}.deep_each.to_a
  #   => [[{:events=>{0=>:title}}, "movie"], [{:events=>{1=>:title}}, "dinner"]]
  #
  # @return an iterator over each deep-key/value pair for every leaf
  def deep_each(&block)
    depth_first_map.each(&block)
  end

  ##
  # Concatenate all the results from the supplied code block together.
  #
  # @return an array with the results of running +block+ once for every leaf element in the original structure, all flattened together.
  #
  # @example
  #  >> {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}.deep_flat_map{|k,v| v*2}
  #  => [2, 4, 6, 8, 10]
  #
  #  >> {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}.deep_flat_map{|k,v| [v, v*2]}
  #  => [1, 2, 2, 4, 3, 6, 4, 8, 5, 10]
  def deep_flat_map(&block)
    deep_each.flat_map(&block)
  end
 
  ##
  # Retrieve a nested element from a DeepEnumerable
  #
  # @example
  #
  #   >> prefix_tree = {"a"=>{"a"=>"aardvark", "b"=>["abacus", "abadon"], "c"=>"actuary"}}
  #
  #   >> prefix_tree.deep_get("a")
  #   => {"a"=>"aardvark", "b"=>["abacus", "abadon"], "c"=>"actuary"}
  #
  #   >> prefix_tree.deep_get("a"=>"b")
  #   => ["abacus", "abadon"]
  #
  # @return a DeepEnumerable representing the subtree specified by the query key
  #
  def deep_get(key)
    if DeepEnumerable::nested_key?(key)
      key_head, key_tail = DeepEnumerable::split_key(key)
      if self[key_head].respond_to?(:deep_get)
        self[key_head].deep_get(key_tail)
      else
        nil #SHOULD? raise an error
      end
    else
      self[key]
    end
  end

  ##
  # Fold over all leaf nodes
  # 
  # @example
  #  >> friends = [{name: 'alice', age: 26}, {name: 'bob', age: 26}]
  #  >> friends.deep_inject(Hash.new{[]}) {|sum, (k, v)| sum[k.values.first] <<= v; sum}
  #  => {:name=>["alice", "bob"], :age=>[26, 26]}
  #
  # @return The accumulation of the results of executing the provided block over every element in the DeepEnumerable
  def deep_inject(initial, &block)
    deep_each.inject(initial, &block)
  end
  
  ##
  # Describes the similarities between two DeepEnumerables.
  #
  # @example
  #  >> alice = {:name=>"alice", :age=>26}
  #  >> bob   = {:name=>"bob",   :age=>26}
  #  >> alice.deep_intersect(bob)
  #  => {:age=>26}
  #
  #  >> bob   = {:friends=>["alice","carol"]}
  #  >> carol = {:friends=>["alice","bob"]}
  #  >> bob.deep_intersect(carol)
  #  => {:friends=>["alice"]}
  #
  # @return a result of the same structure as the primary DeepEnumerable.
  #
  def deep_intersect(other, &block)
    (shallow_keys + other.shallow_keys).each_with_object(empty) do |key, res|
      s_val = (self[key] rescue nil) #TODO don't rely on rescue
      o_val = (other[key] rescue nil)

      comparator = block || :==.to_proc

      if s_val.respond_to?(:deep_intersect) && o_val.respond_to?(:deep_intersect)
        int = s_val.deep_intersect(o_val, &block)
        res[key] = int if int.any?
      elsif comparator.call(s_val, o_val)
        res[key] = s_val
      end
    end
  end

  ##
  # Returns the result of running block on each leaf of this DeepEnumerable
  #
  # @example
  #  >> h = {a: [1, 2]}
  #  >> h.deep_map!{|k, v| [k, v]}
  #  >> h
  #  => {:a=>[[{:a=>0}, 1], [{:a=>1}, 2]]}
  #
  # @return The original structure updated by the result of the block
  def deep_map!(&block)
    if block_given?
      deep_each{|k,v| deep_set(k, block.call([k, v]))}
      self
    else
      deep_each
    end
  end
 
  ##
  # Create a new nested structure populated by the result of executing +block+ on the deep-keys and values of the original DeepEnumerable
  #
  # @example
  #  >> {a: [1, 2]}.deep_map{|k, v| [k, v]}
  #  => {:a=>[[{:a=>0}, 1], [{:a=>1}, 2]]}
  #
  # @return A copy of the input, updated by the result of the block
  def deep_map(&block)
    deep_dup.deep_map!(&block)
  end

  ##
  # Modifies this collection to use the result of +block+ as the values
  #
  # @example
  #  >> h = {a: [1, 2]}
  #  >> h.deep_map_values!{v| v*2}
  #  >> h
  #  => {:a=>[2, 4]}
  #
  # @return The original structure updated by the result of the block
  def deep_map_values!(&block)
    deep_map!{|_, v| block.call(v)}
  end

  ##
  # Creates a new nested structure populated by the result of executing +block+ on the values of the original DeepEnumerable
  #
  # @example
  #  >> {a: [1, 2].deep_map_values{v| v*2}
  #  => {:a=>[2, 4]}
  #
  # @return A copy of the input, updated by the result of the block
  def deep_map_values(&block)
    deep_dup.deep_map_values!(&block)
  end
  
  ##
  # Filter leaf nodes by the result of the given block
  #
  # @example
  #  >> inventory = {fruit: {apples: 4, oranges: 7}}
  #
  #  >> inventory.deep_reject{|k, v| v > 5}
  #  => {:fruit=>{:apples=>4}}
  #
  #  >> inventory.deep_reject(&:even?)
  #  => {:fruit=>{:oranges=>7}}
  #
  # @return a copy of the input, filtered by the given predicate
  #
  def deep_reject(&block)
    new_block =
      case block.arity
      when 2 then ->(k,v){!block.call(k, v)}
      else        ->(v){  !block.call(v)}
      end
    deep_select(&new_block)
  end
 
  ##
  # Filter leaf nodes by the result of the given block
  #
  # @example
  #  >> inventory = {fruit: {apples: 4, oranges: 7}}
  #
  #  >> inventory.deep_select{|k, v| v > 5}
  #  => {:fruit=>{:oranges=>7}}
  #
  #  >> inventory.deep_select(&:even?)
  #  => {:fruit=>{:apples=>4}}
  #
  # @return a copy of the input, filtered by the given predicate
  def deep_select(&block)
    copy = self.select{false} # get an empty version of this shallow collection

    # insert/push a selected item into the copied enumerable
    accept = lambda do |k, v|
      # Don't insert elements at arbitrary positions in an array if appending is an option
      if copy.respond_to?('push') # jruby has a Hash#<< method
        copy.push(v)
      else
        copy[k] = v
      end
    end

    shallow_each do |k, v|
      if v.respond_to?(:deep_select)
        selected = v.deep_select(&block)
        accept.call(k, selected)
      else
        res =
          case block.arity
          when 2 then block.call(k, v)
          else    block.call(v)
          end

        if res
          accept.call(k, (v.dup rescue v)) # FixNum's and Symbol's can't/shouldn't be dup'd
        end
      end
    end
    
    copy
  end

  ##
  # Update a DeepEnumerable, indexed by an Array or Hash.
  #
  # Intermediate values are created when necessary, with the same type as its parent.
  #
  # @example
  #  >> [].deep_set({1 => 2}, 3)
  #  => [nil, [nil, nil, 3]]
  #  >> {}.deep_set([1, 2, 3], 4)
  #  => {1=>{2=>{3=>4}}}
  #
  # @return (tentative) returns the object that's been modified. Warning: This behavior is subject to change.
  #
  def deep_set(key, val)
    if DeepEnumerable::nested_key?(key)
      key_head, key_tail = DeepEnumerable::split_key(key)

      if key_tail.nil?
        self[key_head] = val
      else
        if self[key_head].respond_to?(:deep_set)
          self[key_head].deep_set(key_tail, val)
        else
          self[key_head] = empty.deep_set(key_tail, val)
        end
      end
    elsif !key.nil? # don't index on nil
      self[key] = val
    end

    self #SHOULD? return val instead of self
  end
 
  ##
  # List the values stored at every leaf
  #
  # @example
  #  >> prefix_tree = {"a"=>{"a"=>"aardvark", "b"=>["abacus", "abadon"], "c"=>"actuary"}}
  #  >> prefix_tree.deep_values
  #  => ["aardvark", "abacus", "abadon", "actuary"]
  #
  # @return a list of every leaf value
  def deep_values
    deep_flat_map{|_, v| v}
  end

  ##
  # Combine two DeepEnumerables into one, with the elements from each joined into tuples
  #
  # @example
  #  >> inventory = {fruit: {apples: 4,    oranges: 7}}
  #  >> prices    = {fruit: {apples: 0.79, oranges: 1.21}}
  #  >> inventory.deep_zip(prices)
  #  => {:fruit=>{:apples=>[4, 0.79], :oranges=>[7, 1.21]}}
  #
  # @return one data structure with elements from both arguments joined together
  #
  def deep_zip(other)
    (shallow_keys).inject(empty) do |res, key|
      s_val = self[key]
      o_val = (other[key] rescue nil) #TODO don't rely on rescue

      comparator = :==.to_proc

      if s_val.respond_to?(:deep_zip) && o_val.respond_to?(:deep_zip)
        diff = s_val.deep_zip(o_val)
        diff.empty? ? res : res.deep_set(key, diff)
      else
        res.deep_set(key, [s_val, o_val])
      end
    end
  end

  ##
  # A copy of the DeepEnumerable containing no elements
  #
  # @example
  #  >> inventory = {fruit: {apples: 4, oranges: 7}}
  #  >> inventory.empty
  #  => {}
  #
  # @return a new object of the same type as the original collection, only empty
  #
  def empty
    select{false}
  end
  
  # Provide a homogenous |k,v| iterator for Arrays/Hashes/DeepEnumerables
  #TODO test this
  def shallow_key_value_pairs
    shallow_keys.map{|k| [k, self[k]]}
  end

  ##
  # Replaces every top-level element with the result of the given block
  def shallow_map_keys!(&block)
    new_kvs = shallow_key_value_pairs.map do |k, v|
      new_key = 
        if block.arity == 2
          block.call(k, v)
        else
          block.call(k)
        end

      self.delete(k) #TODO This is not defined on Enumerable!
      [new_key, v]
    end

    new_kvs.each do |k, v|
      self[k] = v
    end

    self
  end
  
  ##
  # Returns a new collection where every top-level element is replaced with the result of the given block
  def shallow_map_keys(&block)
    deep_dup.shallow_map_keys!(&block)
  end
 
  ##
  # Replaces every top-level element with the result of the given block
  def shallow_map_values!(&block)
    shallow_key_value_pairs.each do |k, v|
        self[k] = 
          if block.arity == 2
            block.call(k, v)
          else
            block.call(v)
          end
    end

    self
  end

  ##
  # Returns a new collection where every top-level element is replaced with the result of the given block
  def shallow_map_values(&block)
    deep_dup.shallow_map_values!(&block)
  end
  
  ##
  # The primary iterator of a DeepEnumerable
  # If this method is implemented DeepEnumerable can construct every other method in terms of shallow_each.
  def shallow_each(&block)
    shallow_key_value_pairs.each(&block)
  end

  # This method is commented out because redefining '.to_a' on Array, for example,
  # seems like a terrible idea
  #def to_a
  #  deep_each.to_a
  #end

  protected

  #def shallow_get(x) # this should technically be defined in Hash/Array individually
  #  self[x]
  #end

  def depth_first_map(ancestry=[])
    shallow_each.flat_map do |key, val|
      full_ancestry = ancestry + [key]
      full_key = DeepEnumerable::deep_key_from_array(full_ancestry) #TODO this is an n^2 operation
 
      if val.respond_to?(:depth_first_map, true) # Search protected methods as well
        val.depth_first_map(full_ancestry)
      else
        [[full_key, val]]
      end
    end
  end

  # Everything below should be a class method, but Ruby method visibility is a nightmare
  def self.deep_key_from_array(array)
    if array.size > 1
      {array.first => deep_key_from_array(array.drop(1))}
    else
      array.first
    end
  end

  # DeepEnumerable keys are represented as hashes, this function
  # converts them to arrays for convenience
  def self.deep_key_to_array(key)
    if DeepEnumerable::nested_key?(key)
      head, tail = split_key(key)
      [head] + deep_key_to_array(tail)
    elsif key.nil?
      []
    else
      [key]
    end
  end

  def self.nested_key?(key)
    key.is_a?(Hash) || key.is_a?(Array)
  end

  # Disassembles a key into its head and tail elements
  #
  # @example
  #  >> DeepEnumerable.split_key({a: {0 => :a}})
  #  => [:a, {0 => :a}]
  #  >> DeepEnumerable.split_key([a: [0 => :a]])
  #  => [a:, [0, :a]]
  #
  def self.split_key(key)
    case key
    when Hash then
      key_head = key.keys.first
      key_tail = key[key_head]
      [key_head, key_tail]
    when Array then
      case key.size
        when 0 then [nil, nil]
        when 1 then [key[0], nil]
        else [key[0], key.drop(1)]
      end
    when nil then [nil, nil]
    else [key, nil]
    end
  end

  # Get the lowest-level key
  #
  # for example: {a: {b: :c}} goes to :c
  def self.leaf_key(key)
    nested_key?(key) ? leaf_key(split_key(key)[1]) : key
  end
end

##
# This class implements the necessary methods to qualify Hash as a DeepEnumerable
class Hash
  include DeepEnumerable

  alias_method :shallow_keys, :keys
end

##
# This class implements the necessary methods to qualify Array as a DeepEnumerable
class Array
  include DeepEnumerable

  def shallow_keys
    (0...size).to_a
  end
end
