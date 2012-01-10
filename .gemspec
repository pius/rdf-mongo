#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-mongo'
  gem.homepage           = 'http://github.com/pius/rdf-mongo'
  gem.license            = 'MIT License' if gem.respond_to?(:license=)
  gem.summary            = 'A storage adapter for integrating MongoDB and rdf.rb, a Ruby library for working with Resource Description Framework (RDF) data.'
  gem.description        = 'rdf-mongo is a storage adapter for integrating MongoDB and rdf.rb, a Ruby library for working with Resource Description Framework (RDF) data.'

  gem.authors            = ['Pius Uzamere']
  gem.email              = 'pius@alum.mit.edu'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(LICENSE VERSION README.md) + Dir.glob('lib/**/*.rb')
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = Dir.glob('spec/*.spec')
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.8.7'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',         '>= 0.3.4'
  gem.add_runtime_dependency     'mongo',       '>= 1.5.1'
  gem.add_development_dependency 'rdf-spec',    '>= 0.3.4'
  gem.add_development_dependency 'rspec',       '>= 2.7.0'
  gem.add_development_dependency 'yard' ,       '>= 0.5.3'
  gem.add_runtime_dependency     'addressable', '>= 2.2.6'
  gem.post_install_message       = "Have fun! :)"
end
