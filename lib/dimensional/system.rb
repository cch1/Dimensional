module Dimensional
  # Represents a set of units for comprehensive measurement of physical quantities.
  class System
    @registry = Hash.new
    @abbreviation_registry = Hash.new

    def self.register(*args)
      s = new(*args)
      raise "System #{s.name} already exists" if @registry[s.name]
      raise "System #{s.name}'s abbreviation already exists" if @abbreviation_registry[s.abbreviation]
      @registry[s.name.to_sym] = s
      @abbreviation_registry[s.abbreviation.to_sym] = s if s.abbreviation
      const_set(s.abbreviation, s) rescue nil # Not all symbols strings are valid constant names
      s
    end
    
    # Lookup the system by name or abbreviation
    def self.[](sym)
      return nil unless sym = sym && sym.to_sym
      @abbreviation_registry[sym] || @registry[sym]
    end
    
    # Systems are expected to be declared 'universally' and always be in context so we only dump the name
    def self._load(str)
      @registry[str.to_sym]
    end

    # Purge all systems from storage.
    def self.reset!
      constants.each {|d| remove_const(d)}
      @registry.clear
      @abbreviation_registry.clear
    end

    attr_reader :name, :abbreviation

    def initialize(name, abbreviation = nil)
      @name = name.to_s.freeze
      @abbreviation = abbreviation && abbreviation.to_s
    end
    
    # Systems are expected to be declared 'universally' and always be in context so we only dump the name
    def _dump(depth)
      name
    end

    def to_s
      name rescue super
    end
  end
end