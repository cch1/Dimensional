require 'dimensional/dimension'
require 'dimensional/system'
require 'set'
require 'enumerator'

module Dimensional
  # A standard scale unit for measuring physical quantities.  In addition to the Dimension and System attribute
  # that are well-defined by classes above, the user-defined metric attribute is available to identify units as
  # belonging to an arbitrary metric like length, draft or property size.  Effective use of the metric attribute
  # can simplify presentation of Measures and make parsing of user input more accurate. 
  # Reference: http://en.wikipedia.org/wiki/Units_of_measurement
  class Unit
    @store = Set.new

    def self.register(*args)
      u = new(*args)
      raise "Namespace collision: #{u.dimension}:#{u.system}:#{u.name}" if self[u.dimension, u.system, u.name.to_sym]
      raise "Namespace collision: #{u.dimension}:#{u.system}:#{u.abbreviation}" if self[u.dimension, u.system, u.abbreviation.to_sym] if u.abbreviation
      @store << u
      u
    end

    # Lookup the unit by name or abbreviation, scoped by dimension and system
    def self.[](dim, sys, sym)
      dim = Dimension[dim] unless dim.kind_of?(Dimension)
      sys = System[sys] unless sys.kind_of?(System)
      sym = sym.to_sym
      us = @store.select{|u| u.dimension == dim}.select{|u| u.system == sys}
      us.detect{|u| sym == u.name.to_sym || (u.abbreviation && sym == u.abbreviation.to_sym)}
    end

    def self.reset!
      @store.clear
    end

    attr_reader :name, :abbreviation, :format
    attr_reader :system, :dimension
    attr_reader :reference_factor, :reference_unit

    def initialize(name, system, dimension, options = {})
      @name = name.to_s
      @system = system
      @dimension = dimension
      @reference_factor = options[:reference_factor]
      @reference_unit = options[:reference_unit]
      @detector = options[:detector] || /\A#{self.name}\Z/
      @abbreviation = options[:abbreviation]
      @format = options[:format] || dimension.nil? ? "%s %U" : "%s%U"
    end
    
    def match(s)
      @detector.match(s)
    end

    #  If no reference was provided during initialization, this unit must itself be a base unit.
    def base?
      !reference_unit
    end

    # Returns the unit or array of units on which this unit's scale is ultimately based.
    def base
      return self if base?
      @base ||= reference_unit.kind_of?(Enumerable) ? reference_unit.map{|ru| ru.base} : reference_unit.base
    end
    
    # The conversion factor relative to the base unit.
    def factor
      return 1 if base?
      @factor ||= reference_factor * (reference_unit.kind_of?(Enumerable) ? reference_unit.inject(1){|f, ru| f * ru.factor} : reference_unit.factor)
    end
    
    # Returns the conversion factor to convert to the other unit
    def convert(other)
      raise "Units #{self} and #{other} are not commensurable" unless commensurable?(other)
      return 1 if self == other
      self.factor / other.factor
    end
    
    def commensurable?(other)
      dimension == other.dimension
    end
    
    def to_s
      name rescue super
    end
    
    def inspect
      "#<#{self.class.inspect}: #{dimension.to_s}:#{system.to_s}:#{to_s}>"
    end
  end
end