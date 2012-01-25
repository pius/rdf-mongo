$:.unshift "."
require 'spec_helper'

require 'rdf/spec/repository'
require 'rdf/mongo'

describe RDF::Mongo::Repository do
  context "Mongo RDF Repository" do
    before :each do
      @repository = RDF::Mongo::Repository.new() # TODO: Do you need constructor arguments?
      @repository.coll.drop
    end
   
    after :each do
      @repository.coll.drop
    end

    # @see lib/rdf/spec/repository.rb in RDF-spec
    it_should_behave_like RDF_Repository
  end

end

