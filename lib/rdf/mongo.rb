require 'rdf'
require 'enumerator'
require 'mongo'


module RDF
  class Statement
    def to_mongo
      self.to_hash.inject({}) {|hash, (place_in_statement, entity)| hash.merge(RDF::Mongo::Conversion.to_mongo(entity, place_in_statement)) }
    end
    
    def from_mongo(statement)
      RDF::Statement.new(
        :subject   => RDF::Mongo::Conversion.from_mongo(statement[:s], statement[:st]),
        :predicate => RDF::Mongo::Conversion.from_mongo(statement[:p], statement[:pt]),
        :object    => RDF::Mongo::Conversion.from_mongo(statement[:o], statement[:ot]),
        :context   => RDF::Mongo::Conversion.from_mongo(statement[:c], statement[:ct]))
    end
  end
  
  module Mongo    
    class Conversion
      #what other object types besides URIs and Literals do I need to handle?  BNodes, maybe?
      
      def self.to_mongo(value, place_in_statement)
        case value
        when RDF::URI
          v, k = value.to_s, :u
        when RDF::Literal
          v, k = value.value, :l
        else
          v, k = value.to_s, :u
        end
        
        case place_in_statement
        when :subject
          t, k1 = :st, :s
        when :predicate
          t, k1 = :pt, :p
        when :object
          t, k1 = :ot, :o
        when :context
          t, k1 = :ct, :c
        end
        return {k1 => v, t => k}
      end

      def self.from_mongo(value, value_type = :u)
        case value_type
        when :u
          RDF::URI.new(value)
        when :l
          RDF::Literal.new(value)
        end
      end
    end
    
    
    class Repository < ::RDF::Repository
      
      def db
        @db
      end
      
      def coll
        @coll
      end

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
                  :subject   => RDF::Mongo::Conversion.from_mongo(statement[:s], statement[:st]),
                  :predicate => RDF::Mongo::Conversion.from_mongo(statement[:p], statement[:pt]),
                  :object    => RDF::Mongo::Conversion.from_mongo(statement[:o], statement[:ot]),
                  :context   => RDF::Mongo::Conversion.from_mongo(statement[:c], statement[:ct])))
                }
        else
          #::Enumerable::Enumerator.new(self,:each)
          statements = @coll.find()
          statements.send(:each)
        end
      end

      # @see RDF::Mutable#insert_statement
      def insert_statement(statement)
        @coll.update(statement.to_mongo, statement.to_mongo, :upsert => true)
      end

      # @see RDF::Mutable#delete_statement
      def delete_statement(statement)
        @coll.remove(statement.to_mongo)
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
