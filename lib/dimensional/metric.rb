require 'dimensional/dimension'

module Dimensional
  # A specific physical entity that can be measured.
  # TODO: Add a hierarchy that allows metrics to be grouped by domain, like shipping, carpentry or sports
  class Metric
    include Enumerable

    @registry = Hash.new

    attr_reader :name, :dimension, :parent

    def self.register(*args)
      m = new(*args)
      raise "Metric #{m} has already been registered." if @registry[m.name]
      @registry[m.name && m.name.to_sym] = m
      m
    end

    # Lookup the metric by key.  The default metric for a dimension is keyed by the dimension's symbol
    def self.[](sym)
      @registry[sym && sym.to_sym]
    end

    def self.reset!
      @registry.clear
    end

    def initialize(name, dimension, parent = nil)
      @name = name && name.to_s
      @dimension = dimension
      @units = {}
      @parent = parent
    end
  
    def prefer(unit, options = {})
      raise "Unit #{unit} is not compatible with dimension #{dimension || '<nil>'}." unless unit.dimension == dimension
      @units[unit] = options
    end

    def units
      baseline = parent ? parent.units : @units.keys
      baseline.sort_by{|u| [1.0 - preference(u), u.name, u.system]}
    end
  
    def preferences(u)
      baseline = parent ? parent.preferences(u) : {} 
      baseline.merge(@units[u] || {})
    end
    
    # How "preferred" is the given unit for this metric?
    def preference(u)
      @units.has_key?(u) ? 1 : 0
    end

    def each
      units.each
    end

    def to_s
      name || super
    end
  end
end