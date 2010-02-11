# encoding: UTF-8
require 'dimensional/dimension'
require 'dimensional/system'
require 'dimensional/unit'
require 'dimensional/metric'

module Dimensional
  # A little DSL for defining units.  Beware of Ruby 1.8 binding a block variable
  # to a local variable if they have the same name -it can subtly goof things up.
  class Configurator
    # A simple container for holding a context for definition, parsing and formatting of dimensional data
    Context = Struct.new(:system, :dimension, :unit) do
      def valid?
        true
      end
    end

    attr_reader :context

    # Start the configurator with the given context hash and evaluate the supplied block
    def self.start(c_hash = {}, &block)
      new.change_context(c_hash, block)
    end

    def self.dimension_default_metric_name(d)
      d && d.symbol
    end

    def initialize(c = Context.new)
      @context = c
      raise "Invalid context" unless context.valid?
    end

    # Change the context, either for the scope of the supplied block or for this instance
    # NB: The scope in which constants (and classes) are evaluated in instance_eval is surprising in some
    # versions of Ruby.  Reference: http://groups.google.com/group/ruby-talk-google/browse_thread/thread/186ac9e618a7312d/a8c5dafa7fcfa3dd?lnk=raot
    def change_context(c_hash, block = nil)
      new_context = context.dup
      c_hash.each{|k, v| new_context[k] = v}
      if block
        self.class.new(new_context).instance_eval &block
      else
        self # Allow chaining
      end
    end

    # Change dimension of the context to the given dimension (or its symbol)
    def dimension(d = nil, &block)
      d = Dimension[d] unless d.kind_of?(Dimension)
      change_context({:dimension => d}, block)
    end

    # Change system of the context to the given system (or its abbreviation)
    def system(s = nil, &block)
      s = System[s] unless s.kind_of?(System)
      change_context({:system => s}, block)
    end

    # Register a new base unit
    def base(name, abbreviation = nil, options = {}, &block)
      u = unit(name, {:abbreviation => abbreviation}.merge(options))
      change_context({:unit => u}, block)
    end

    # Register a new derived unit
    def derive(name, abbreviation, factor, options = {}, &block)
      u = unit(name, {:abbreviation => abbreviation, :reference_units => {context.unit => 1}, :reference_factor => factor}.merge(options))
      change_context({:unit => u}, block)
    end

    # Register an alias for the unit in context
    def alias(name, abbreviation = nil, options = {}, &block)
      derive(name, abbreviation, 1, options, &block)
    end

    # Register a new unit in the current context that references an arbitrary unit
    def reference(name, abbreviation, ru, f, options = {}, &block)
      u = unit(name, {:abbreviation => abbreviation, :reference_units => {ru => 1}, :reference_factor => f}.merge(options))
      change_context({:unit => u}, block)
    end

    # Register a new unit in the current context that is composed of multiple units
    def combine(name, abbreviation, components, options = {}, &block)
      u = unit(name, {:abbreviation => abbreviation, :reference_factor => 1, :reference_units => components}.merge(options))
      change_context({:unit => u}, block)
    end

    def to_s
      context.to_s
    end

    private
    def unit(name, options = {})
      Unit.register(name, context.system, context.dimension, options)
    end
  end
end