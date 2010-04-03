# RDF.rb storage adapter skeleton

This is a skeleton repository to create your own RDF.rb storage adapter.  It's
designed to get you up and running with a new backend as quickly as possible,
so that you can have working tests right away, allowing you to develop
iteratively.

# Getting started:

 1. Ensure you have the requirements below.
 1. Run the tests.  You'll get a lot of `NotImplementedErrors`
 1. Find and fix the TODO markers in `lib/rdf/myrepository.rb`.   
 1. Find and fix the TODO markers in `spec/my_repository.spec`.  You may not need to do this if your repository needs no arguments to `new()`.
 1. Run the tests!  Man, you're awesome!

To run tests, run:

    spec -cfn spec/my_repository.spec

## Requirements

You'll need the `rdf`, `rdf-spec`, and `rspec` libraries.  The easiest way to install these is via RubyGems.

    $ sudo gem install rdf rdf-spec rspec

## Resources

 * <http://rdf.rubyforge.org>


### Author
 * Ben Lavender | <blavender@gmail.com> | <http://github.com/bhuga> | <http://bhuga.net> | <http://blog.datagraph.org>

### 'License'

This is free and unemcumbered software released into the public domain.  For
more information, see the accompanying UNLICENSE file.

If you're unfamiliar with public domain, that means it's perfectly fine to
start with this skeleton and code away, later relicensing as you see fit.

