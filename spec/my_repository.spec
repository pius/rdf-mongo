$:.unshift File.dirname(__FILE__) + "/../lib/"

require 'rdf'
require 'rdf/spec/repository'
require 'rdf/myrepository'

describe RDF::MyRepository do
  context "My New RDF Repository" do
    before :each do
      @repository = RDF::MyRepository.new() # TODO: Do you need constructor arguments?
    end
   
    after :each do
      #TODO: Anything you need to clean up a test goes here.
      @repository.clear
    end

    # @see lib/rdf/spec/repository.rb in RDF-spec
    it_should_behave_like RDF_Repository
  end

end

