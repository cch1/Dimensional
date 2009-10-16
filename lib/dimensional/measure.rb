require 'dimensional/unit'
require 'dimensional/metric'
require 'delegate'

module Dimensional
  # A numeric-like class used to represent the measure of a physical quantity.  An instance of this
  # class represents both the unit and the numerical value of a measure.  In turn, the (scale)
  # unit implies a dimension of the measure.  Instances of this class are immutable (value objects)
  # Reference: http://en.wikipedia.org/wiki/Physical_quantity
  class Measure < DelegateClass(Numeric)
    # A Measure string is composed of a number followed by a unit separated by optional whitespace.
    # A unit (optional) is composed of a non-digit character followed by zero or more word characters and terminated by some stuff.
    # Scientific notation is not currently supported.
    NUMERIC_REGEXP = /((?=\d|\.\d)\d*(?:\.\d*)?)\s*(\D\w*?)?(?=\b|\d|\W|$)/
  
    # Parse a string into a Measure instance.  The metric and system parameters may be keys for looking up the associated values. 
    # Unrecognized strings return nil.
    def self.parse(str, metric, system = nil)
      metric = Metric[metric] unless metric.kind_of?(Metric)
      system = System[system] unless system.kind_of?(System)
      raise "Metric not specified" unless metric
      units = metric.units
      elements = str.to_s.scan(NUMERIC_REGEXP).map do |(v, us)|
        units = units.select{|u| system == u.system} if system
        unit = us.nil? ? units.first : units.detect{|u| u.match(us.to_s)}
        raise ArgumentError, "Unit cannot be determined (#{us})" unless unit
        system = unit.system
        value = unit.dimension.nil? ? v.to_i : v.to_f
        new(value, unit, metric)
      end
      # Coalesce the elements into a single Measure instance in "expression base" units.
      # The expression base is the first provided unit in an expression like "1 mile 200 feet"
      elements.inject do |t, e|
        converted_value = e.convert(t.unit)
        new(t + converted_value, t.unit, metric)
      end
    end

    attr_reader :unit, :metric

    def initialize(value, unit, metric = nil)
      @unit = unit
      metric = Metric[metric] if metric.kind_of?(Symbol)
      @metric = metric || Metric[unit.dimension]
      super(value)
    end

    # Convert this dimensional value to a different unit
    def convert(new_unit)
      new_value = self * unit.convert(new_unit)
      self.class.new(new_value, new_unit, metric)
    end

    # Return a new dimensional value expressed in the base unit
    # DEPRECATE: this method has dubious semantics for composed units as there may be no defined unit with
    # a matching dimension vector.
    def base
      raise "Composed units cannot be converted to a base unit" if unit.reference_unit.kind_of?(Enumerable)
      convert(unit.base)
    end

    def native
      metric.dimension ? to_f : to_i
    end

    def to_s
      strfmeasure(metric.preferences(unit)[:format]) rescue super
    end

    # Like Date, Time and DateTime, Measure represents both a value and a context.  Like those built-in classes,
    # Measure needs this output method to control the context.  The format string is identical to that used by
    # Kernel.sprintf with the addition of support for the U specifier:
    #   %U  replace with unit.  This specifier supports the '#' flag to use the unit's name instead of abbreviation
    #       In addition, this specifier supports the same width and precision modfiers as the '%s' specifier.  
    #       For example: %#10.10U
    # All other specifiers are applied to the numeric value of the measure.
    # TODO: Support positional arguments (n$).
    # TODO: Support modulo subordinate units with format hash -> {1 => "'", 12 => :inch} or {1 => "%d#", 16 => "%doz."}
    def strfmeasure(format = nil, *args)
      v = if precision = metric.preferences(unit)[:precision]
        pfactor = 10**(-precision)
        ((self * pfactor).round / pfactor.to_f).to_s
      else
        native
      end
      format = format || unit.format
      format.gsub!(/%(#)?([\d.\-\*]*)U/) do |s|
        arg = ($1) ? unit.name : unit.abbreviation
        Kernel.sprintf("%#{$2}s", arg)
      end
      Kernel.sprintf(format, v, *args)
    end

    def inspect
      "#{super} : #{unit.inspect}"
    end
  end
end