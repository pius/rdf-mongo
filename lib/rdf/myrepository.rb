require 'rdf'
require 'enumerator'

module RDF
  class MyRepository < ::RDF::Repository

    def initialize(options = {})
      #TODO: Configure initialization
      #
      # @statements = []
      raise NotImplementedError
    end
 
    # @see RDF::Enumerable#each.
    def each(&block)
      if block_given?
        #TODO: produce an RDF::Statement, then:
        # block.call(RDF::Statement)
        #
        # @statements.each do |s| block.call(s) end
        raise NotImplementedError
      else
        ::Enumerable::Enumerator.new(self,:each)
      end
    end

    # @see RDF::Mutable#insert_statement
    def insert_statement(statement)
      #TODO: save the given RDF::Statement.  Don't save duplicates.
      #
      #@statements.push(statement.dup) unless @statements.member?(statement)
      raise NotImplementedError
    end

    # @see RDF::Mutable#delete_statement
    def delete_statement(statement)
      #TODO: delete the given RDF::Statement from the repository.  It's not an error if it doesn't exist.
      #
      # @statements.delete(statement)
      raise NotImplementedError
    end

  end
end
