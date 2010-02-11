# encoding: UTF-8
module Dimensional
  # A Locale is a prioritized list of Systems per Metric.
  # Locales solve the problem of parsing ambiguous units such as US gallons and Imperial gallons. They also allow
  # unit systems to be prioritized for specific metrics.  For example, in the domain of aeronautics, the "international
  # nautical mile" is used universally for distances and "knots" are used for speed.  For these metrics, an "International"
  # system should have the highest priority when parsing ambiguous units and when formatting output.
  class Locale
    class << self
      # The default locale, which is used when auto-creating locales.
      def default
        @default ||= self.new(:DEFAULT)
      end

      # Create a new locale and define a constant for it
      def register(name, ss = Array.new)
        l = new(name, ss)
        const_set(l.to_s.to_sym, l)
      end

      # Create a new locale (using systems from the default locale) and define a constant for it
      def const_missing(symbol)
        register(symbol, default.systems.dup) # Copy default's systems for independence
      end

      def reset!
        @default = nil
        constants.each {|d| remove_const(d)}
      end
    end

    attr_accessor :systems
    # Locales have a prioritized list of systems and a name.
    def initialize(name, ss = Array.new)
      @name = name
      @systems = ss
    end

    def to_s
      @name.to_s
    end
  end
end