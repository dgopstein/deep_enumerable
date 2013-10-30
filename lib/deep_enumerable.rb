##
# A set of general methods that can be applied to any conformant nested structure
module DeepEnumerable
  ##
  # Deeply copy a DeepEnumerable
  def deep_dup
    deep_each.map(&:dup)
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

  ##
  # Returns an array with the results of running block once for every leaf element in the original structure.
  #
  # Example:
  #  >> {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}.deep_map{|k,v| v*2}
  #  => [2, 4, 6, 8, 10]
  def deep_map(&block)
    deep_each.map(&block) # TODO this is wrong, copy Scala's Map.map behavior
  end
  #
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
    if key.is_a?(Hash)
      top_key = key.keys.first
      if self[top_key].respond_to?(:deep_set)
        self[top_key].deep_set(key[top_key], val)
	self
      else
        self[top_key] = {}.deep_set(key[top_key], val)
	self
      end
    else
      self[key] = val
      self
    end
  end

  protected
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

  # should be a class method, but Ruby method visibility is a nightmare
  def deep_key_from_array(array)
    if array.size > 1
      {array.first => deep_key_from_array(array.drop(1))}
    else
      array.first
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
