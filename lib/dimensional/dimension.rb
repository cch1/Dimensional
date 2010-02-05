module Dimensional
  # Represents a dimension that can be used to characterize a physical quantity.  With the exception of certain
  # fundamental dimensions, all dimensions are expressed as a set of exponents relative to the fundamentals.
  # Reference: http://en.wikipedia.org/wiki/Dimensional_analysis
  class Dimension
    @registry = Hash.new
    @symbol_registry = Hash.new # Not a Ruby Symbol but a (typically one-character) natural language symbol

    def self.register(*args)
      d = new(*args)
      raise "Dimension #{d}'s symbol already exists" if @symbol_registry[d.symbol]
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

    attr_reader :name, :symbol, :basis

    def initialize(name, symbol = nil, basis = {})
      basis.each_pair do |k,v|
        raise "Invalid fundamental dimension #{k}" unless k.fundamental?
        raise "Invalid exponent for basis member #{v}" unless v.kind_of?(Integer)  # Can't this really be any Rational?
      end
      @basis = Hash.new(0).merge(basis)
      @name = name.to_s
      @symbol = symbol.nil? ? name.to_s.slice(0, 1).upcase : symbol.to_s
    end
    
    def fundamental?
      basis.empty?
    end
    alias base? fundamental?

    # Equality is determined by equality of value-ish attributes.  Specifically, equal basis for non-fundamental units
    # and identicality for fundamental units.  The nil dimension is inherently un-equal to any non-nil dimension.
    def ==(other)
      other.kind_of?(self.class) && ((fundamental? && other.fundamental?) ? eql?(other) : other.basis == basis)
    end

    # Hashing collisions are desired when we have same identity-defining attributes.
    def eql?(other)
      other.kind_of?(self.class) && other.name.eql?(self.name)
    end

    # This is pretty lame, but the expected usage means we shouldn't get penalized
    def hash
      [self.class, name].hash
    end

    def to_s
      name rescue super
    end
    
    def to_sym
      symbol.to_sym
    end
  end
end