require 'rdf'
require 'enumerator'
require 'mongo'

module RDF
  module Mongo
    class Repository < ::RDF::Repository

    def initialize(options = {:host => 'localhost', :port => 27017, :db => 'quadb'})
      @db = ::Mongo::Connection.new(options[:host], options[:port]).db(options[:db])
      @coll = @db['quads']
    end
 
    # @see RDF::Enumerable#each.
    def each(&block)
      if block_given?
        statements = @coll.find()
        statements.each {|statement|
          block.call(RDF::Statement.new(
                :subject   => statement[:s],
                :predicate => statement[:p],
                :object    => statement[:o],
                :context   => statement[:c]))
              }
      else
        ::Enumerable::Enumerator.new(self,:each)
      end
    end

    # @see RDF::Mutable#insert_statement
    def insert_statement(statement)
      @coll.update({:s => statement.subject, :p => statement.predicate, :o => statement.object, :c => statement.context},
                          {:s => statement.subject, :p => statement.predicate, :o => statement.object, :c => statement.context},
                          true)
    end

    # @see RDF::Mutable#delete_statement
    def delete_statement(statement)
      @coll.remove({:s => statement.subject, :p => statement.predicate, :o => statement.object, :c => statement.context})
    end
    
    def count
      @coll.count
    end
    
    def query(pattern, &block)
      case pattern
        when RDF::Statement
          query(pattern.to_hash)
        when Array
          query(RDF::Statement.new(*pattern))
        when Hash
          statements = query_hash(pattern)
          case block_given?
            when true
              statements.each(&block)
            else
              statements.extend(RDF::Enumerable, RDF::Queryable)
          end
        else
          super(pattern) 
      end
    end
    
    def query_hash(hash)
      h = {}
      (h[:s] = hash[:subject]) if hash[:subject]
      (h[:p] = hash[:predicate]) if hash[:predicate]
      (h[:o] = hash[:object]) if hash[:object]
      (h[:c] = hash[:context]) if hash[:context]
      @coll.find(h)
    end
  end
  end
end
