##
# This class implements the necessary methods to qualify Hash as a DeepEnumerable
class Hash
  ##
  # Iterate elements of a deeply nested hash
  #
  # Example:
  #   >> {a: {b: 1, c: 2}}.deep_each
  #   => [[{:a=>:b}, 1], [{:a=>:c}, 2]]
  def deep_each(ancestry=[])
    flat_map do |key, val|
      full_ancestry = ancestry + [key]
      full_key = Hash.deep_key_from_array(full_ancestry) #TODO this is an n^2 operation

      if val.respond_to?(:deep_each)
        val.deep_each(full_ancestry)
      else
        [[full_key, val]]
      end
    end
  end

  def self.deep_key_from_array(array)
    if array.size > 1
      {array.first => Hash.deep_key_from_array(array.drop(1))}
    else
      array.first
    end
  end
end
