Deep Enumerable (pre-alpha) [![Oh Noes!](https://travis-ci.org/dgopstein/deep_enumerable.png?branch=master)](https://travis-ci.org/dgopstein/deep_enumerable)
===============

A library for manipulating nested collections in Ruby

## What is a nested collection?
A nested collection is a data structure wrapped in another datastructure!

For example, a flat array might look like: `[1, 2, 3]` while a nested array might look like: `[1, [2, 3]]`

Many other collections can be nested as well, e.g. Hashes: `{:a => :b, :c => {:d => :e}}`

Collection can even be nested inside collections of a different type, as in lists of hashes: `[{:name => 'alice'}, {:name => 'bob'}]`, or hashes of lists: `{:name => 'carol', :favorite_colors => [:yellow, :blue]}`

## Why do we need DeepEnumerable?

Ruby has excellent native support for a few common collections such as Array, Hash, Set and Range. At the heart of each of these collection libraries is the Enumerable module which provides dozens of general purpose methods (map, inject, select) implemented on top of each base class's :each method. Enumerable's methods make operating on traditional collections clear, concise and less error prone. Dealing with nested collections, however, is still relatively clunky. Consider a simple logging configuration:

```ruby
>> conf_values = {
     :level => :error,
     :appender => {
       :file => '/var/log/error',
       :poll_interval => :∞
     }
   }
```

We might reasonably want to do some sanity checking on the types of the configuration. For instance, if :max_size were not an integer we would like to know before trying to operate on that value. With vanilla ruby we would need to imperatively test every element, which is very tedious:

```ruby
>> Symbol === conf_values[:level]
=> true
>> String === conf_values[:appender][:file]
=> true
>> Fixnum === conf_values[:appender][:poll_interval]
=> false
```

Instead using a DeepEnumerable we can model our rules as data, and find an errors in a single expression:

```ruby
>> conf_types = {
     :level => Symbol,
     :appender => {
       :file => String,
       :poll_interval => Fixnum
     }  
   }

>> conf_types.deep_diff(conf_values, &:===.to_proc)
=> {:appender=>{:poll_interval=>[Fixnum, :∞]}}

```

DeepEnumerable is an attempt to create a human-oriented general purpose collection library for nested collections. Code reuse.



Iterate elements of a DeepEnumerable:
>> {event: {id: 1, title: 'bowling'}}.deep_each.to_a
=> [[{:event=>:id}, 1], [{:event=>:title}, "bowling"]]

>> [:a, [:b, :c]].deep_each.to_a
=> [[0, :a], [{1=>0}, :b], [{1=>1}, :c]]

>> {events: [{title: 'movie'}, {title: 'dinner'}]}.deep_each.to_a
=> [[{:events=>{0=>:title}}, "movie"], [{:events=>{1=>:title}}, "dinner"]]
