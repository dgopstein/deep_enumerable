##
# A set of general methods that can be applied to any conformant nested structure
class DeepEnumerable
  ##
  # Turns a list of parent nodes into an accessor key
  #
  # Example:
  #   >> DeepEnumerable.deep_key_from_array([:events, 3, :title])
  #   => {:events=>{3=>:title}}
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
  #   >> {event: {id: 1, title: 'bowling'}}.deep_each
  #   => [[{:event=>:id}, 1], [{:event=>:title}, "bowling"]]
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
  #   >> [:a, [:b, :c]].deep_each
  #   => [[0, :a], [{1=>0}, :b], [{1=>1}, :c]]
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
