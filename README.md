DeepEnumerable (α) [![Oh Noes!](https://travis-ci.org/dgopstein/deep_enumerable.png?branch=master)](https://travis-ci.org/dgopstein/deep_enumerable) [![Code Climate](https://codeclimate.com/github/dgopstein/deep_enumerable/badges/gpa.svg)](https://codeclimate.com/github/dgopstein/deep_enumerable)
===============

A library for manipulating nested collections in Ruby

## Installation

```gem install deep_enumerable```

## Usage

```require 'deep_enumerable'```

## Docs
http://www.rubydoc.info/gems/deep_enumerable/DeepEnumerable

## What is a nested collection?
A nested collection is a data structure wrapped in another data structure!

For example, a flat array might look like: `[1, 2, 3]` while a nested array might look like: `[1, [2, 3]]`

Other collections can be nested as well, e.g. Hashes: `{:a => :b, :c => {:d => :e}}`

Collections can even be nested inside collections of a different type, as in lists of hashes: `[{:name => 'alice'}, {:name => 'bob'}]`, or hashes of lists: `{:name => 'carol', :favorite_colors => [:yellow, :blue]}`

## What is DeepEnumerable?

Ruby has excellent native support for a few common collections such as Array, Hash, Set and Range. At the heart of each of these collection libraries is the Enumerable module which provides dozens of general purpose methods (map, inject, select) implemented on top of each base class's `:each` method. Enumerable's methods make operating on traditional collections clear, concise and less error prone. Dealing with nested collections, however, is still relatively clunky. Consider a simple logging configuration:

```ruby
>> conf_values = {
     :level => :error,
     :appender => {
       :file => '/var/log/error',
       :update_interval => :∞
     }
   }
```

We might reasonably want to do some sanity checking on the types of the configuration. For instance, if `:update_interval` were not an integer we would like to know before trying to operate on that value. With vanilla ruby we would need to imperatively test every element, which is tedious and potentially error producing:

```ruby
>> Symbol === conf_values[:level]
=> true
>> String === conf_values[:appender][:file]
=> true
>> Fixnum === conf_values[:appender][:update_interval]
=> false
>> String === conf_values[:output][:format]
NoMethodError: undefined method `[]' for nil:NilClass
```

Instead using a DeepEnumerable we can model our rules as data, and find errors in a single expression:

```ruby
>> conf_types = {
     :level => Symbol,
     :appender => {
       :file => String,
       :update_interval => Fixnum
     },
     :output => {:format => String}
   }

>> conf_types.deep_outersect(conf_values, &:===)
=> {:appender=>{:update_interval=>[Fixnum, :∞]}, :output=>[{:format=>String}, nil]}

```

## What else is DeepEnumerable?

DeepEnumerable provides a few interesting methods on a couple different standard data structures. Here are some examples:

Iterate and transform leaf nodes:
```ruby
>> {a: {b: 1, c: {d: 2, e: 3}, f: 4}, g: 5}.deep_flat_map{|k,v| v*2}
=> [2, 4, 6, 8, 10]
```

Retrieve a nested element from a DeepEnumerable:

```ruby
>> prefix_tree = {"a"=>{"a"=>"aardvark", "b"=>["abacus", "abaddon"], "c"=>"actuary"}}
>> prefix_tree.deep_get("a"=>"b")
=> ["abacus", "abadon"]
```

## What else could be a DeepEnumerable in the future?

Right now DeepEnumerable ships with default implementations for Array's and Hash's. Like Enumerable, all of DeepEnumerable's methods are built on top of only a single iterator, `:shallow_keys`, which means if your data structure implements `:shallow_keys`, your data structure can simply include the DeepEnumerable module and get a mixin-ful of useful methods. If implementing your own `:shallow_keys` sounds scary, just look to the default implementations in Array and Hash - they're quite modest:

Hash:
```ruby
alias_method :shallow_keys, :keys
```

Array:
```ruby
def shallow_keys
  (0...size).to_a
end
```

## Contributing

Pull requests welcome.
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so we don't break it in a future version unintentionally.
* Submit a pull request
