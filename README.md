Deep Enumerable (pre-alpha) [![Oh Noes!](https://travis-ci.org/dgopstein/deep_enumerable.png?branch=master)](https://travis-ci.org/dgopstein/deep_enumerable)
===============

A library for manipulating nested collections in Ruby

## What is a nested collection?
A nested collection is a data structure wrapped in another datastructure!

For example, a flat array might look like: `[1, 2, 3]` while a nested array might look like: `[1, [2, 3]]`

Many other collections can be nested as well, e.g. Hashes: `{:a => :b, :c => {:d => :e}}`

Collection can even be nested inside collections of a different type, as in lists of hashes: `[{:name => 'alice'}, {:name => 'bob'}]`, or hashes of lists: `{:name => 'carol', :favorite_colors => [:yellow, :blue]}`

## What inspired Deep Enumerable?

Ruby has excellent native support for a few common collections such as Array, Hash, Set and Range. At the heart of each of these collection libraries is the Enumerable module which provides dozens of general purpose methods (map, inject, select) implemented on top of each base class's :each method. Enumerable's methods make operating on traditional collections clear, concise and error prone, however dealing with nested is still relatively clunky. Consider a simple logging configuration:

```ruby
loggers = [
  {
    :level => 'error',
    :output_locations => ['STDERR', '/var/log/error']
  },
  {
    :level => 'info',
    :output_locations => ['STDOUT', '/var/log/info']
  }
}
```

DeepEnumerable is an attempt to create a human-oriented general purpose collection library for nested collections. Code reuse.



Iterate elements of a DeepEnumerable:
>> {event: {id: 1, title: 'bowling'}}.deep_each.to_a
=> [[{:event=>:id}, 1], [{:event=>:title}, "bowling"]]

>> [:a, [:b, :c]].deep_each.to_a
=> [[0, :a], [{1=>0}, :b], [{1=>1}, :c]]

>> {events: [{title: 'movie'}, {title: 'dinner'}]}.deep_each.to_a
=> [[{:events=>{0=>:title}}, "movie"], [{:events=>{1=>:title}}, "dinner"]]
