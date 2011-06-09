require 'rdf'
require 'enumerator'
require 'mongo'

module Mongo
  class Cursor
    def rdf_each(&block)
      if block_given?
        each {|statement| block.call(RDF::Statement.from_mongo(statement)) }
      else
        self
      end
    end
  end
end
      
module RDF
  class Statement
    def to_mongo
      self.to_hash.merge({:context => self.context}).inject({}) { |hash, (place_in_statement, entity)| 
        hash.merge(RDF::Mongo::Conversion.to_mongo(entity, place_in_statement)) 
        }
    end
    
    def self.from_mongo(statement)
      RDF::Statement.new(
        :subject   => RDF::Mongo::Conversion.from_mongo(statement['s'], statement['st'], statement['sl']),
        :predicate => RDF::Mongo::Conversion.from_mongo(statement['p'], statement['pt'], statement['pl']),
        :object    => RDF::Mongo::Conversion.from_mongo(statement['o'], statement['ot'], statement['ol']),
        :context   => RDF::Mongo::Conversion.from_mongo(statement['c'], statement['ct'], statement['cl']))
    end
  end
  
  module Mongo    
    class Conversion
      #TODO: Add support for other types of entities
      
      def self.to_mongo(value, place_in_statement)
        case value
        when RDF::URI
          v, k = value.to_s, :u
        when RDF::Literal
          v, k, ll = value.value, :l, value.language
        when RDF::Node
          v, k = value.id.to_s, :n
        when nil
          v, k = nil, nil
        else
          v, k = value.to_s, :u
        end
        
        case place_in_statement
        when :subject
          t, k1, lt = :st, :s, :sl
        when :predicate
          t, k1, lt = :pt, :p, :pl
        when :object
          t, k1, lt = :ot, :o, :ol
        when :context
          t, k1, lt = :ct, :c, :cl
        end
        h = {k1 => (v == '' ? nil : v), t => (k == '' ? nil : k), lt => ll}
        h.delete_if {|k,v| h[k].nil?}
      end

      def self.from_mongo(value, value_type = :u, lang = nil)
        case value_type
        when :u
          RDF::URI.new(value)
        when :l
          RDF::Literal.new(value, :language => lang)
        when :n
          RDF::Node.new(value)
        end
      end
    end
    
    
    class Repository < ::RDF::Repository
      
      def self.load(filenames, options = {:host => 'localhost', :port => 27017, :db => 'quadb'}, &block)
        self.new(options) do |repository|
          [filenames].flatten.each do |filename|
            repository.load(filename, options)
          end

          if block_given?
            case block.arity
              when 1 then block.call(repository)
              else repository.instance_eval(&block)
            end
          end
        end
      end
      
      def db
        @db
      end
      
      def coll
        @coll
      end

      def initialize(options = {:host => 'localhost', :port => 27017, :db => 'quadb'})
        @db = ::Mongo::Connection.new(options[:host], options[:port]).db(options[:db])
        @coll = @db['quads']
        @coll.create_index("s")
        @coll.create_index("p")
        @coll.create_index("o")
        @coll.create_index("c")
        @coll.create_index([["s", ::Mongo::ASCENDING], ["p", ::Mongo::ASCENDING]])
        @coll.create_index([["s", ::Mongo::ASCENDING], ["o", ::Mongo::ASCENDING]])
        @coll.create_index([["p", ::Mongo::ASCENDING], ["o", ::Mongo::ASCENDING]])
      end
 
      # @see RDF::Enumerable#each.
      def each(&block)
        if block_given?
          statements = @coll.find()
          statements.each {|statement| block.call(RDF::Statement.from_mongo(statement)) }
        else
          statements = @coll.find()
          enumerator!.new(statements,:rdf_each)
        end
      end

      # @see RDF::Mutable#insert_statement
      def supports?(feature)
        case feature.to_sym
          when :context then true
          else false
        end
      end
      
      def insert_statement(statement)
        @coll.update(statement.to_mongo, statement.to_mongo, :upsert => true)
      end

      # @see RDF::Mutable#delete_statement
      def delete_statement(statement)
        case statement.context
        when nil
          @coll.remove(statement.to_mongo.merge('ct'=>nil))
        else
          @coll.remove(statement.to_mongo)
        end
      end
    
      def count
        @coll.count
      end
    
      def query(pattern, &block)
        case pattern
          when RDF::Statement
            query(pattern.to_hash, &block)
          when Array
            query(RDF::Statement.new(*pattern), &block)
          when Hash 
            statements = query_hash(pattern)
            the_statements = statements || []            
            case block_given?
              when true
                the_statements.each {|s| block.call(RDF::Statement.from_mongo(s))}
              else
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
                s = the_statements.to_enum.extend(RDF::Enumerable, RDF::Queryable)
            end
          else
            super(pattern) 
        end
      end
    
      def query_hash(hash)
        return @coll.find if hash.empty?
        h = RDF::Statement.new(hash).to_mongo
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
