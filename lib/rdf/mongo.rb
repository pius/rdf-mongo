require 'rdf'
require 'enumerator'
require 'mongo'

module Mongo
  class Cursor
    def rdf_each(&block)
      if block_given?
        each {|statement| block.call(RDF::Statement.from_mongo(statement)) }
      else
        self#each {|statement| RDF::Statement.from_mongo(statement) }
      end
    end
  end
end
      
module RDF
  class Statement
    def to_mongo
      self.to_hash.inject({}) {|hash, (place_in_statement, entity)| hash.merge(RDF::Mongo::Conversion.to_mongo(entity, place_in_statement)) }
    end
    
    def self.from_mongo(statement)
      RDF::Statement.new(
        :subject   => RDF::Mongo::Conversion.from_mongo(statement['s'], statement['st']),
        :predicate => RDF::Mongo::Conversion.from_mongo(statement['p'], statement['pt']),
        :object    => RDF::Mongo::Conversion.from_mongo(statement['o'], statement['ot']),
        :context   => RDF::Mongo::Conversion.from_mongo(statement['c'], statement['ct']))
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
        when nil
          v, k = nil, nil
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
        h = {k1 => (v == '' ? nil : v), t => (k == '' ? nil : k)}
        h.delete_if {|k,v| h[k].nil?}
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
          statements.each {|statement| block.call(RDF::Statement.from_mongo(statement)) }
        else
          statements = @coll.find()
          enumerator!.new(statements,:rdf_each)
          #nasty ... in Ruby 1.9, Enumerator doesn't exist under Enumerable
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
            the_statements = statements || []            
            case block_given?
              when true
                the_statements.each {|s| block.call(RDF::Statement.from_mongo(s))}
              else
                #e = enumerator!.new(statements.extend(RDF::Queryable),:rdf_each)
                #s = the_statements.extend(RDF::Enumerable, RDF::Queryable)
                def the_statements.each(&block)
                  if block_given?
                    super {|statement| block.call(RDF::Statement.from_mongo(statement)) }
                  else
                    enumerator!.new(the_statements,:rdf_each)
                  end
                end
                
                def the_statements.size
                  count
                end
                s = the_statements
            end
          else
            super(pattern) 
        end
      end
    
      def query_hash(hash)
        return @coll.find if hash.empty?
        h = RDF::Statement.new(hash).to_mongo
        # h = {}
        # (h[:s] = hash[:subject]) if hash[:subject]
        # (h[:p] = hash[:predicate]) if hash[:predicate]
        # (h[:o] = hash[:object]) if hash[:object]
        # (h[:c] = hash[:context]) if hash[:context]
        @coll.find(h)
      end
      
      
      private

        def enumerator! # @private
          require 'enumerator' unless defined?(::Enumerable)
          @@enumerator_klass = defined?(::Enumerable::Enumerator) ? ::Enumerable::Enumerator : ::Enumerator
        end
      
      
    end
  end
end
