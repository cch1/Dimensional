require 'dimensional/unit'
require 'delegate'

module Dimensional
  # A specific physical entity that can be measured.
  # TODO: Add a hierarchy that allows metrics to be built into a taxonomy by domain, like shipping, carpentry or sports
  class Metric < DelegateClass(Numeric)
    # A Measure string is composed of a number followed by a unit separated by optional whitespace.
    # A unit (optional) is composed of a non-digit character followed by zero or more word characters and terminated by some stuff.
    # Scientific notation is not currently supported.
    NUMERIC_REGEXP = /((?=\d|\.\d)\d*(?:\.\d*)?)\s*(\D\w*?)?(?=\b|\d|\W|$)/

    class << self
      attr_accessor :dimension, :base, :default

      # The units applicable to this metric in priority order (highest priority first)
      def units
        @units ||= Unit.select{|u| u.dimension == dimension}.sort_by{|u| configuration[u][:preference]}.reverse
      end

      # Find the unit matching the given string, preferring units in the given system
      def find_unit(str, system = nil)
        system = System[system] unless system.kind_of?(System)
        us = self.units.select{|u| configuration[u][:detector].match(str.to_s)}
        us.detect{|u| u.system == system} || us.first
      end

      def configuration
        @configuration ||= Hash.new do |h,u|
          h[u] = {:detector => u.detector, :format => u.format, :preference => u.preference}
        end
      end

      def configure(unit, options = {})
        @dimension ||= unit.dimension
        @base ||= unit.base
        @default ||= unit.base
        @units = nil
        raise "Unit #{unit} is not compatible with dimension #{dimension || '<nil>'}." unless unit.dimension == dimension
        configuration[unit] = {:detector => unit.detector, :format => unit.format, :preference => unit.preference * 1.01}.merge(options)
      end

      # Parse a string into a Metric instance. Providing a unit system (or associated symbol) will prefer the units from that system.
      # Unrecognized strings return nil.
      def parse(str, system = nil)
        system = System[system] unless system.kind_of?(System)
        elements = str.to_s.scan(NUMERIC_REGEXP).map do |(v, us)|
          unit = us.nil? ? default : find_unit(us, system)
          raise ArgumentError, "Unit cannot be determined (#{us})" unless unit
          system = unit.system # Set the system to restrict subsequent filtering
          value = unit.dimension.nil? ? v.to_i : v.to_f # Ugly...
          new(value, unit)
        end
        # Coalesce the elements into a single Measure instance in "expression base" units.
        # The expression base is the first provided unit in an expression like "1 mile 200 feet"
        elements.inject do |t, e|
          raise ArgumentError, "Inconsistent units in compound metric" unless t.unit.system == e.unit.system
          converted_value = e.convert(t.unit)
          new(t + converted_value, t.unit)
        end
      end
    end

    attr_reader :unit
    def initialize(value, unit = self.class.default)
      raise ArgumentError, "No default unit set" unless unit
      @unit = unit
      super(value)
    end

    # Convert this dimensional value to a different unit
    def convert(new_unit)
      new_value = self * unit.convert(new_unit)
      self.class.new(new_value, new_unit)
    end

    # Convert this measure to the most appropriate unit in the given system
    # A heuristic approach is used that considers the resulting measure's order-of-magnitude (similar
    # is good) and preference of the unit (greater is better).
    def change_system(system, fallback = false)
      system = System[system] unless system.kind_of?(System)
      units = self.class.units.select{|u| system == u.system}
      if units.empty?
        if fallback
          units = self.units
        else
          raise "No suitable units available in #{system}"
        end
      end
      target_oom = Math.log10(self.unit.factor)
      units = units.sort_by do |u|
        oom_delta = (Math.log10(u.factor) - target_oom).abs #  == Math.log10(self.unit.factor / u.factor)
        magnitude_fit = Math.exp(-0.20 * oom_delta) # decay function
        0.75 * magnitude_fit + 0.25 * self.class.configuration[u][:preference]
      end
      u = units.last
      convert(u)
    end

    # Return a new metric expressed in the base unit
    def base
      raise "Composed units cannot be converted to a base unit" if unit.reference_unit.kind_of?(Enumerable)
      raise "No base unit defined" unless self.class.base
      convert(self.class.base)
    end

    def to_s
      strfmeasure(self.class.configuration[unit][:format])
    end

    # Like Date, Time and DateTime, Metric represents both a value and a context.  Like those built-in classes,
    # Metric needs this output method to control the context.  The format string is identical to that used by
    # Kernel.sprintf with the addition of support for the U specifier:
    #   %U  replace with unit.  This specifier supports the '#' flag to use the unit's name instead of abbreviation
    #       In addition, this specifier supports the same width and precision modfiers as the '%s' specifier.
    #       For example: %#10.10U
    # All other specifiers are applied to the numeric value of the measure.
    # TODO: Support modulo subordinate units with format hash -> {1 => "'", 12 => :inch} or {1 => "%d#", 16 => "%doz."}
    def strfmeasure(format)
      # We need the native value to prevent infinite recursion if the user specifies the %s specifier.
      v = if (precision = self.class.configuration[unit][:precision])
        pfactor = 10**(-precision)
        ((self * pfactor).round / pfactor.to_f)
      else
        __getobj__
      end
      format = format.gsub(/%(#)?([\d.\-\*]*)U/) do |s|
        us = ($1) ? unit.name : (unit.abbreviation || unit.name)
        Kernel.sprintf("%#{$2}s", us)
      end
      count = format.scan(/(?:\A|[^%])(%[^% ]*[A-Za-z])/).size
      Kernel.sprintf(format, *Array.new(count, v))
    end

    def inspect
      strfmeasure("<%p <%#U>>")
    end
  end
end