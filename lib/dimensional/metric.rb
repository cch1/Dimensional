require 'dimensional/unit'
require 'delegate'

module Dimensional
  # A specific physical entity that can be measured.
  # TODO: Add a hierarchy that allows metrics to be built into a taxonomy by domain, like shipping, carpentry or sports
  class Metric < DelegateClass(Numeric)
    # A Measure string is composed of a number followed by a unit separated by optional whitespace.
    # A unit (optional) is composed of a non-digit character followed by zero or more word characters and terminated by some stuff.
    # Scientific notation is not currently supported.
    # TODO: Move this to a locale
    NUMERIC_REGEXP = /((?=\d|\.\d)\d*(?:\.\d*)?)\s*(\D.*?)?\s*(?=\d|$)/

    class << self
      attr_accessor :dimension, :base, :default, :universal_systems

      # The units of this metric, grouped by system.
      def units
        @units ||= Hash.new([]).merge(Unit.select{|u| u.dimension == dimension}.group_by{|u| u.system})
      end

      def systems(locale)
        locale.systems.dup.unshift(*(universal_systems || [])).uniq
      end

      # Find the unit matching the given string, preferring units in the given locale
      def find_unit(str, locale = Locale.default)
        us = systems(locale).inject([]){|us, system| us + units[system].sort_by{|u| configuration[u][:preference]}.reverse}
        us.detect{|u| configuration[u][:detector].match(str.to_s)}
      end

      def configuration
        @configuration ||= Hash.new do |h,u|
          h[u] = {:detector => u.detector, :format => u.format, :preference => u.preference}
        end
      end

      def configure(unit, options = {})
        @dimension ||= unit.dimension
        @base ||= unit
        @default ||= unit
        raise "Unit #{unit} is not compatible with dimension #{dimension || '<nil>'}." unless unit.dimension == dimension
        configuration[unit] = {:detector => unit.detector, :format => unit.format, :preference => unit.preference * 1.01}.merge(options)
      end

      # Parse a string into a Metric instance. Providing a locale will help resolve ambiguities.
      # Unrecognized strings return nil.
      def parse(str, locale = Locale.default)
        elements = str.to_s.scan(NUMERIC_REGEXP).map do |(v, us)|
          unit = us.nil? ? default : find_unit(us, locale)
          raise ArgumentError, "Unit cannot be determined (#{us})" unless unit
          value = Integer(v) rescue Float(v)
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

      # Sort units by "best" fit for the desired order of magnitude.  Preference values offset OOM differences.  There is
      # a bias in favor of positive OOM differences (humans like 6" more than 0.5ft).
      def best_fit(target_oom, system)
        us = units[system]
        us = us.sort_by do |u|
          oom_delta = Math.log10(u.factor) - target_oom
          (configuration[u][:preference] - oom_delta.abs) + (oom_delta <=> 0.0)*0.5
        end
        us.last
      end

      # Create a new instance with the given value (assumed to be in the base unit) and convert it to the preferred unit.
      def load(v)
        new(v, base).preferred
      end
    end

    attr_reader :unit
    def initialize(value, unit = self.class.default || self.class.base)
      raise ArgumentError, "No default unit set" unless unit
      @unit = unit
      super(value)
    end

    # Convert this dimensional value to a different unit
    def convert(new_unit)
      new_value = self * unit.convert(new_unit)
      self.class.new(new_value, new_unit)
    end

    # Convert into the "most appropriate" unit in the given system.  A similar order-of-magnitude for the result is preferred.
    def change_system(system)
      system = System[system] unless system.kind_of?(System)
      target_oom = Math.log10(self.unit.factor)
      bu = self.class.best_fit(target_oom, system)
      convert(bu)
    end

    # Convert into the best unit for the given Locale.  The first system of the given locale with units is elected the preferred system,
    # and within the preferred system, preference is given to units yielding a metric whose order of magnitude is close to zero.
    def localize(locale = Locale.default)
      target_oom = Math.log10(self) + Math.log10(self.unit.factor)
      preferred_system = self.class.systems(locale).detect{ |s| self.class.units[s].any? }
      bu = self.class.best_fit(target_oom, preferred_system)
      convert(bu)
    end
    alias preferred localize

    # Return a new metric expressed in the base unit
    def base
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
      v = if (precision = self.class.configuration[unit][:precision])
        # TODO: This precision could more usefully be converted to "signifigant digits"
        pfactor = 10**(-precision)
        ((self * pfactor).round / pfactor.to_f)
      else
        __getobj__ # We need the native value to prevent infinite recursion if the user specifies the %s specifier.
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