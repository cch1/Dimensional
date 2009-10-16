module Dimensional
  # Represents a dimension that can be used to characterize a physical quantity.  With the exception of certain
  # fundamental dimensions, all dimensions are expressed as a set of exponents relative to the fundamentals.
  # Reference: http://en.wikipedia.org/wiki/Dimensional_analysis
  class Dimension
    @registry = Hash.new
    @symbol_registry = Hash.new # Not a Ruby Symbol but a (typically one-character) natural language symbol

    def self.register(*args)
      d = new(*args)
      raise "Dimension #{d.name} already exists" if @registry[d.name]
      raise "Dimension #{d.name}'s symbol already exists" if @symbol_registry[d.symbol]
      @registry[d.name.to_sym] = d
      @symbol_registry[d.symbol.to_sym] = d
      const_set(d.symbol.to_s, d) rescue nil # Not all symbols strings are valid constant names
      d
    end

    # Lookup the dimension by name or symbol
    def self.[](sym)
      return nil unless sym = sym && sym.to_sym
      @registry[sym] || @symbol_registry[sym]
    end
    
    # Purge all dimensions from storage.
    def self.reset!
      constants.each {|d| remove_const(d)}
      @registry.clear
      @symbol_registry.clear
    end

    attr_reader :exponents, :name, :symbol

    def initialize(name, symbol = nil, exponents = {})
      exponents.each_pair do |k,v|
        raise "Invalid fundamental dimension #{k}" unless k.fundamental?
        raise "Invalid exponent #{v}" unless v.kind_of?(Integer)  # Can't this really be any Rational?
      end
      @exponents = Hash.new(0).merge(exponents)
      @name = name.to_s
      @symbol = symbol.nil? ? name.to_s.slice(0, 1).upcase : symbol.to_s
    end
    
    def fundamental?
      exponents.empty?
    end

    def to_s
      name rescue super
    end
    
    def to_sym
      symbol.to_sym
    end
  end
end