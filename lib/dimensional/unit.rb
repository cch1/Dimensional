require 'dimensional/dimension'
require 'dimensional/system'
require 'set'
require 'rational'

module Dimensional
  # A standard scale unit for measuring physical quantities.  In addition to the Dimension and System attribute
  # that are well-defined by classes above, the user-defined metric attribute is available to identify units as
  # belonging to an arbitrary metric like length, draft or property size.  Effective use of the metric attribute
  # can simplify presentation of Measures and make parsing of user input more accurate.
  # Reference: http://en.wikipedia.org/wiki/Units_of_measurement
  class Unit
    extend Enumerable

    @store = Set.new

    def self.each(&block)
      @store.each(&block)
    end

    def self.register(*args)
      u = new(*args)
      raise "Namespace collision: #{u.inspect}" if @store.include?(u)
      @store << u
      u
    end

    # Lookup the unit by name or abbreviation, scoped by dimension and system
    def self.[](dim, sys, sym)
      dim = Dimension[dim] unless dim.kind_of?(Dimension)
      sys = System[sys] unless sys.kind_of?(System)
      sym = sym.to_sym
      us = @store.select{|u| u.dimension == dim}.select{|u| u.system == sys}
      u = us.detect{|u| sym == u.name.to_sym || (u.abbreviation && sym == u.abbreviation.to_sym)}
      u || (raise ArgumentError, "Can't find unit: #{dim}, #{sys}, #{sym}")
    end

    def self.reset!
      @store.clear
    end

    attr_reader :name, :abbreviation
    attr_reader :system, :dimension
    attr_reader :reference_factor, :reference_units
    attr_reader :detector, :format, :preference

    def initialize(name, system, dimension, options = {})
      @name = name.to_s
      @system = system
      @dimension = dimension
      @reference_factor = options[:reference_factor] || 1
      @reference_units = options[:reference_units] || {}
      @abbreviation = options[:abbreviation]
      @detector = options[:detector] || /\A#{[name, abbreviation].compact.join('|')}\Z/
      @format = options[:format] || dimension.nil? ? "%s %U" : "%s%U"
      @preference = options[:preference] || 0
      validate
    end

    def validate
      return "Reference factor must be numeric: #{@reference_factor}." unless factor.kind_of?(Numeric)
      return "Reference units must all be units: #{@reference_units}." unless reference_units.all?{|u, exp| u.kind_of?(Dimensional::Unit)}
      return "Reference exponents must all be rationals: #{@reference_units}." unless reference_units.all?{|u, exp| exp.kind_of?(Rational)}
      return "Preference must be numeric: #{@preference}." unless preference.kind_of?(Numeric)
    end

    #  If no reference was provided during initialization, this unit must itself be a base unit.
    def base?
      reference_units.empty?
    end

    # Returns the unit or array of units on which this unit's scale is ultimately based.
    # The technique used is to multiply the bases' exponents by our exponent and then consolidate
    # resulting common bases by adding their exponents.
    def base
      return {self => 1} if base?
      @base ||= reference_units.inject({}) do |summary0, (ru0, exp0)|
        t = ru0.base.inject({}){|summary1, (ru1, exp1)| summary1[ru1] = exp1 * exp0;summary1}
        summary0.merge(t) {|ru, expa, expb| expa + expb}
      end
    end

    # The conversion factor relative to the base unit.
    def factor
      @factor ||= reference_factor * reference_units.inject(1){|f, (ru, exp)| f * (ru.factor**exp)}
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

    # Equality is determined by equality of value-ish attributes.  Specifically, equal factors relative to the same base.
    def ==(other)
      (other.base == self.base) && other.factor == self.factor
    end

    # Hashing collisions are desired when we have same identity-defining attributes.
    def eql?(other)
      other.kind_of?(self.class) && other.dimension.eql?(self.dimension) && other.system.eql?(self.system) && other.name.eql?(self.name)
    end

    # This is pretty lame, but the expected usage means we shouldn't get penalized
    def hash
      [self.class, dimension, system, name].hash
    end

    def to_s
      name rescue super
    end

    def inspect
      "#<#{self.class.inspect}: #{dimension.to_s}:#{system.to_s}:#{to_s}>"
    end
  end
end