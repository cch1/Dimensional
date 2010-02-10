require 'delegate'

module Dimensional
  # Represents a set of units for comprehensive measurement of physical quantities.
  class System < DelegateClass(String)
    @registry = Hash.new
    @abbreviation_registry = Hash.new

    def self.register(*args)
      s = new(*args)
      raise "System #{s} already exists" if @registry[s.to_sym]
      raise "System #{s}'s abbreviation already exists" if @abbreviation_registry[s.abbreviation]
      @registry[s.to_sym] = s
      @abbreviation_registry[s.abbreviation.to_sym] = s if s.abbreviation
      const_set(s.abbreviation, s) rescue nil # Not all symbols strings are valid constant names
      s
    end

    # Lookup the system by name or abbreviation
    def self.[](sym)
      sym = sym && sym.to_sym
      s = @abbreviation_registry[sym] || @registry[sym]
      raise "Unknown system #{sym.to_s}" unless s
      s
    end

    # Purge all systems from storage.
    def self.reset!
      constants.each {|d| remove_const(d)}
      @registry.clear
      @abbreviation_registry.clear
    end

    attr_reader :abbreviation, :description

    def initialize(name, abbreviation = nil, description = nil)
      @abbreviation = abbreviation && abbreviation.to_s
      @description = description || name
      super(name)
    end
  end
end