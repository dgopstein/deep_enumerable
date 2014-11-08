##
# A set of general methods that can be applied to any conformant nested structure
module DeepEnumerable

  #TODO test this
  def shallow_each(&block)
    shallow_keys.map{|k| [k, self[k]]}.each(&block)
  end
    
  # Provide a homogenous |k,v| iterator for Arrays/Hashes/DeepEnumerables
  def key_value_pairs
    shallow_keys.map{|k| [k, self[k]]}
  end

  ##
  # Replaces every top-level element with the result of the given block
  def map_keys!(&block)
    new_kvs = key_value_pairs.map do |k, v|
      new_key = 
        if block.arity == 2
          block.call(k, v)
        else
          block.call(k)
        end

      self.delete(k)
      [new_key, v]
    end

    new_kvs.each do |k, v|
      self[k] = v
    end

    self
  end
  
  ##
  # Returns a new collection where every top-level element is replaced with the result of the given block
  def map_keys(&block)
    deep_dup.map_keys!(&block)
  end
 
  ##
  # Replaces every top-level element with the result of the given block
  def map_values!(&block)
    key_value_pairs.each do |k, v|
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
  def map_values(&block)
    deep_dup.map_values!(&block)
  end

  ##
  # Deeply copy a DeepEnumerable
  def deep_dup
    copy = self.dup
    shallow_each do |k, v|
      if v.respond_to?(:deep_dup)
        copy[k] = v.deep_dup
      else
        copy[k] = (v.dup rescue v) # FixNum's and Symbol's can't/shouldn't be dup'd
      end
    end
    copy
  end

  ##
  # Iterate elements of a DeepEnumerable
  #
  # Example:
  #   >> {event: {id: 1, title: 'bowling'}}.deep_each.to_a
  #   => [[{:event=>:id}, 1], [{:event=>:title}, "bowling"]]
  # 
  #   >> [:a, [:b, :c]].deep_each.to_a
  #   => [[0, :a], [{1=>0}, :b], [{1=>1}, :c]]
  #
  #   >> {events: [{title: 'movie'}, {title: 'dinner'}]}.deep_each.to_a
  #   => [[{:events=>{0=>:title}}, "movie"], [{:events=>{1=>:title}}, "dinner"]]
  def deep_each(&block)
    depth_first_map.each(&block)
  end

  def to_a
    deep_each.to_a
  end

  ##
  # Returns an array with the results of running block once for every leaf element in the original structure.
  #
  # Example:
  #  >> {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}.deep_flat_map{|k,v| v*2}
  #  => [2, 4, 6, 8, 10]
  def deep_flat_map(&block)
    deep_each.map(&block)
  end

  ##
  # Returns the result of running block on each leaf of this DeepEnumerable
  def deep_map!(&block)
    if block_given?
      deep_each{|k,v| deep_set(k, block.call([k, v]))}
      self
    else
      deep_each
    end
  end
 
  ##
  # Returns a new nested structure where the result of running block is used as the values
  def deep_map(&block)
    deep_dup.deep_map!(&block)
  end

  ##
  # Return all leaf values
  def deep_values
    deep_flat_map{|_, v| v}
  end

  ##
  # Modifies this collection to use the result of block as the values
  def deep_map_values!(&block)
    deep_map!{|_, v| block.call(v)}
  end

  ##
  # Returns a new nested structure where the result of running block is used as the values
  def deep_map_values(&block)
    deep_dup.deep_map_values!(&block)
  end

  # Fold over all leaf nodes
  def deep_inject(initial, &block)
    deep_each.inject(initial, &block)
  end

  ##
  # Describes the differences between two DeepEnumerables. The structure
  # of the union of both collections is mapped onto a hash. For any element
  # that differs between collections, values are placed into a length-2 array
  #
  # Example:
  #
  # >> {:name=>"alice", :age=>25}.deep_diff(:name=>"bob", :age=>25)
  # => {:name=>["alice", "bob"]}
  #
  # >> bob = {:friends=>["alice","carol"]}
  # >> carol = {:friends=>["alice","bob"]}
  # >> bob.deep_diff(carol)
  # => {:friends=>{1=>["carol", "bob"]}}
  #
  def deep_diff(other, &block)
    (shallow_keys + other.shallow_keys).inject({}) do |res, key|
      s_val = (self[key] rescue nil) #TODO don't rely on rescue
      o_val = (other[key] rescue nil)

      comparator = block || :==.to_proc

      if s_val.respond_to?(:deep_diff) && o_val.respond_to?(:deep_diff)
        diff = s_val.deep_diff(o_val, &block)
        diff.empty? ? res : res.merge(key => diff)
      elsif comparator.call(s_val, o_val)
        res
      else
        res.merge(key => [s_val, o_val])
      end
    end
  end

  ##
  # Update a DeepEnumerable using a hash accessor
  #
  def deep_set(key, val)
    if nested_key?(key)
      key_head, key_tail = split_key(key)
      if self[key_head].respond_to?(:deep_set)
        self[key_head].deep_set(key_tail, val)
	self
      else
        self[key_head] = {}.deep_set(key_tail, val) #SHOULD? this default to {}?
	self
      end
    else
      self[key] = val
      self #SHOULD? return val instead of self
    end
  end

  ##
  # Retrieve a nested element from a DeepEnumerable
  #
  # Example:
  #
  # >> {"a"=>{"a"=>"aardvark", "b"=>["abacus", "abadon"], "c"=>"actuary"}}.deep_get("a"=>"b")
  # => ["abacus", "abadon"]
  #
  def deep_get(key)
    if nested_key?(key)
      key_head, key_tail = split_key(key)
      if self[key_head].respond_to?(:deep_get)
        self[key_head].deep_get(key_tail)
      else
        nil #SHOULD? raise an error
      end
    else
      self[key]
    end
  end

  protected

  #def shallow_get(x) # this should technically be defined in Hash/Array individually
  #  self[x]
  #end

  def depth_first_map(ancestry=[])
    shallow_each.flat_map do |key, val|
      full_ancestry = ancestry + [key]
      full_key = deep_key_from_array(full_ancestry) #TODO this is an n^2 operation
 
      if val.respond_to?(:depth_first_map, true) # Search protected methods as well
        val.depth_first_map(full_ancestry)
      else
        [[full_key, val]]
      end
    end
  end

  # Everything below should be a class method, but Ruby method visibility is a nightmare
  def deep_key_from_array(array)
    if array.size > 1
      {array.first => deep_key_from_array(array.drop(1))}
    else
      array.first
    end
  end

  def nested_key?(key)
    key.is_a?(Hash)
  end

  def split_key(key)
    case key
    when Hash then
    key_head = key.keys.first
    key_tail = key[key_head]
    [key_head, key_tail]
    when nil then [nil, nil]
    else [key, nil]
    end
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
