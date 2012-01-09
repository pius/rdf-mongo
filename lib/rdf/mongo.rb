require 'rdf'
require 'enumerator'
require 'mongo'

module RDF
  class Statement
    ##
    # Creates a BSON representation of the statement.
    # @return [Hash]
    def to_mongo
      self.to_hash.inject({}) do |hash, (place_in_statement, entity)| 
        hash.merge(RDF::Mongo::Conversion.to_mongo(entity, place_in_statement)) 
      end
    end
    
    ##
    # Create BSON for a statement representation. Note that if the statement has no context,
    # a value of `false` will be used to indicate the default context
    #
    # @param [RDF::Statement] statement
    # @return [Hash] Generated BSON representation of statement.
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
      ##
      # Translate an RDF::Value type to BSON key/value pairs.
      #
      # @param [RDF::Value, Symbol, false, nil] value
      #   URI, BNode or Literal. May also be a Variable or Symbol to indicate
      #   a pattern for a named context, or `false` to indicate the default context.
      #   A value of `nil` indicates a pattern that matches any value.
      # @param [:subject, :predicate, :object, :context]
      #   Position within statement.
      # @return [Hash] BSON representation of the statement
      def self.to_mongo(value, place_in_statement)
        case value
        when RDF::URI
          v, k = value.to_s, :u
        when RDF::Literal
          if value.has_language?
            v, k, ll = value.value, :ll, value.language.to_s
          elsif value.has_datatype?
            v, k, ll = value.value, :lt, value.datatype.to_s
          else
            v, k, ll = value.value, :l, nil
          end
        when RDF::Node
          v, k = value.id.to_s, :n
        when RDF::Query::Variable, Symbol
          # Returns anything other than the default context
          v, k = nil, {"$ne" => :default}
        when false
          # Used for the default context
          v, k = false, :default
        when nil
          v, k = nil, nil
        else
          v, k = value.to_s, :u
        end
        v = nil if v == ''
        
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
        h = {k1 => v, t => k, lt => ll}
        h.delete_if {|k,v| h[k].nil?}
      end

      ##
      # Translate an BSON positional reference to an RDF Value.
      #
      # @return [RDF::Value]
      def self.from_mongo(value, value_type = :u, literal_extra = nil)
        case value_type
        when :u
          RDF::URI.intern(value)
        when :ll
          RDF::Literal.new(value, :language => literal_extra.to_sym)
        when :lt
          RDF::Literal.new(value, :datatype => RDF::URI.intern(literal_extra))
        when :l
          RDF::Literal.new(value)
        when :n
          @nodes ||= {}
          @nodes[value] ||= RDF::Node.new(value)
        when :default
          nil # The default context returns as nil, although it's queried as false.
        end
      end
    end

    class Repository < ::RDF::Repository
      attr_reader :db
      attr_reader :coll
      
      ##
      # Initializes this repository instance.
      #
      # @param  [Hash{Symbol => Object}] options
      # @option options [URI, #to_s]    :uri (nil)
      # @option options [String, #to_s] :title (nil)
      # @option options [String] :host
      # @option options [Integer] :port
      # @option options [String] :db
      # @yield  [repository]
      # @yieldparam [Repository] repository
      def initialize(options = {}, &block)
        options = {:host => 'localhost', :port => 27017, :db => 'quadb'}.merge(options)
        @db = ::Mongo::Connection.new(options[:host], options[:port]).db(options[:db])
        @coll = @db['quads']
        @coll.create_index("s")
        @coll.create_index("p")
        @coll.create_index("o")
        @coll.create_index("c")
        @coll.create_index([["s", ::Mongo::ASCENDING], ["p", ::Mongo::ASCENDING]])
        @coll.create_index([["s", ::Mongo::ASCENDING], ["o", ::Mongo::ASCENDING]])
        @coll.create_index([["p", ::Mongo::ASCENDING], ["o", ::Mongo::ASCENDING]])
        super(options, &block)
      end

      # @see RDF::Mutable#insert_statement
      def supports?(feature)
        case feature.to_sym
          when :context then true
          else false
        end
      end
      
      def insert_statement(statement)
        st_mongo = statement.to_mongo
        st_mongo[:ct] ||= :default # Indicate statement is in the default context
        #puts "insert statement: #{st_mongo.inspect}"
        @coll.update(st_mongo, st_mongo, :upsert => true)
      end

      # @see RDF::Mutable#delete_statement
      def delete_statement(statement)
        case statement.context
        when nil
          @coll.remove(statement.to_mongo.merge('ct'=>:default))
        else
          @coll.remove(statement.to_mongo)
        end
      end

      ##
      # @private
      # @see RDF::Durable#durable?
      def durable?; true; end

      ##
      # @private
      # @see RDF::Countable#empty?
      def empty?; @coll.count == 0; end

      ##
      # @private
      # @see RDF::Countable#count
      def count
        @coll.count
      end

      ##
      # @private
      # @see RDF::Enumerable#has_statement?
      def has_statement?(statement)
        !!@coll.find_one(statement.to_mongo)
      end
      ##
      # @private
      # @see RDF::Enumerable#each_statement
      def each_statement(&block)
        @nodes = {} # reset cache. FIXME this should probably be in Node.intern
        if block_given?
          @coll.find() do |cursor|
            cursor.each do |data|
              block.call(RDF::Statement.from_mongo(data))
            end
          end
        end
        enum_statement
      end
      alias_method :each, :each_statement

      ##
      # @private
      # @see RDF::Enumerable#has_context?
      def has_context?(value)
        !!@coll.find_one(RDF::Mongo::Conversion.to_mongo(value, :context))
      end

      ##
      # @private
      # @see RDF::Queryable#query
      # @see RDF::Query::Pattern
      def query_pattern(pattern, &block)
        @nodes = {} # reset cache. FIXME this should probably be in Node.intern

        # A pattern context of `false` is used to indicate the default context
        pm = pattern.to_mongo
        pm.merge!(:c => nil, :ct => :default) if pattern.context == false
        puts "query using #{pm.inspect}"
        @coll.find(pm) do |cursor|
          cursor.each do |data|
            block.call(RDF::Statement.from_mongo(data))
          end
        end
      end
    
      private

        def enumerator! # @private
          require 'enumerator' unless defined?(::Enumerable)
          @@enumerator_klass = defined?(::Enumerable::Enumerator) ? ::Enumerable::Enumerator : ::Enumerator
        end
    end
  end
end
