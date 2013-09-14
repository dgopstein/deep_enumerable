##
# A set of general methods that can be applied to any conformant nested structure
module DeepEnumerable
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

  ##
  # Iterate elements of a deeply nested structure
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
    deep_each_depth_first_map.each(&block)
  end

  def deep_each_depth_first_map(ancestry=[]) #TODO make this private
    shallow_each.flat_map do |key, val|
      full_ancestry = ancestry + [key]
      full_key = DeepEnumerable.deep_key_from_array(full_ancestry) #TODO this is an n^2 operation
 
      if val.respond_to?(:deep_each_depth_first_map)
        val.deep_each_depth_first_map(full_ancestry)
      else
        [[full_key, val]]
      end
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
