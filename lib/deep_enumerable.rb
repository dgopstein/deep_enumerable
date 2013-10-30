##
# A set of general methods that can be applied to any conformant nested structure
module DeepEnumerable
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
  #  >> {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}.deep_map{|k,v| v*2}
  #  => [2, 4, 6, 8, 10]
  def deep_map_leafs(&block)
    deep_each.map(&block)
  end

  ##
  # Returns a new nested structure where the result of running block is used as the values
  #def deep_map_values(&block)
  #  deep_dup
  #end

  ##
  # Returns a new nested structure where the result of running block is used as the values
  def deep_map_values(&block)
    deep_dup
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

  alias_method :shallow_each, :each
end

##
# This class implements the necessary methods to qualify Array as a DeepEnumerable
class Array
  include DeepEnumerable

  def shallow_each
    each_with_index.map{|*a| a.reverse}
  end
end
