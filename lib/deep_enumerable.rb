##
# A set of general methods that can be applied to any conformant nested structure
class DeepEnumerable
  def self.deep_key_from_array(array)
    if array.size > 1
      {array.first => DeepEnumerable.deep_key_from_array(array.drop(1))}
    else
      array.first
    end
  end
end

##
# This class implements the necessary methods to qualify Hash as a DeepEnumerable
class Hash
  ##
  # Iterate elements of a deeply nested hash
  #
  # Example:
  #   >> {a: {b: 1, c: 2}}.deep_each
  #   => [[{:a=>:b}, 1], [{:a=>:c}, 2]]
  def deep_each(ancestry=[]) #TODO remove need for ancestry param
    flat_map do |key, val|
      full_ancestry = ancestry + [key]
      full_key = DeepEnumerable.deep_key_from_array(full_ancestry) #TODO this is an n^2 operation

      if val.respond_to?(:deep_each)
        val.deep_each(full_ancestry)
      else
        [[full_key, val]]
      end
    end
  end
end

##
# This class implements the necessary methods to qualify Array as a DeepEnumerable
class Array
  ##
  # Iterate elements of a deeply nested array
  #
  # Example:
  #   >> [1, [2, 3]].deep_each
  #   => [[0, 1], [{1=>0}, 2], [{1=>1}, 3]]
  def deep_each(ancestry=[])
    each_with_index.flat_map do |val, key|
      full_ancestry = ancestry + [key]
      full_key = DeepEnumerable.deep_key_from_array(full_ancestry) #TODO this is an n^2 operation

      if val.respond_to?(:deep_each)
        val.deep_each(full_ancestry)
      else
        [[full_key, val]]
      end
    end
  end
end
