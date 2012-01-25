$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "bundler/setup"
require 'rspec'
require 'rdf/mongo'

RSpec.configure do |config|
  #config.include(RDF::Spec::Matchers)
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.exclusion_filter = {
    :ruby           => lambda { |version| RUBY_VERSION.to_s !~ /^#{version}/},
    :blank_nodes    => 'unique',
    :arithmetic     => 'native',
    :sparql_algebra => false,
    #:status         => 'bug',
    :reduced        => 'all',
  }
end
