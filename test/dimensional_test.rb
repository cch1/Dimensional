# encoding: UTF-8
require 'helper'

class DimensionalTest < Test::Unit::TestCase
  include Dimensional

  def setup
    load 'test/demo.rb'
    @forestry = Class.new(Metric)
    @forestry.instance_eval do
      self.dimension = Dimension::A
      configure(Unit[:A, :SI, :hectare], :precision => -4, :format => "%s%U")
    end
  end

  def teardown
    Dimension.reset!
    System.reset!
    Unit.reset!
    Locale.reset!
  end

  def test_a_lot
    100.times do
      assert m0 = @forestry.parse("1 acre")
      assert u2 = Unit[:A, :SI, 'hectare']
      assert m2 = m0.convert(u2)
      assert_in_delta 0.40468564224, m2, 0.00001
      assert_equal "0.4047ha", m2.to_s
    end
  end

  def test_engine_displacement
    assert m = EngineDisplacement.load(5.7)
    assert_equal 5.7, m
    assert_same Unit[:V, :SI, 'liter'], m.unit
    m = m.localize(Locale::US)
    assert_in_delta 347, m, 1
    assert_same Unit[:V, :US, 'in3'], m.unit
  end

  def test_mechanical_power
    assert m = MechanicalPower.parse('430hp')
    assert_equal 430, m
    assert_same Unit[:P, :US, :hp], m.unit
    m = m.localize(Locale::FI)
    assert_in_delta 320, m, 1
    assert_same Unit[:P, :SI, :kW], m.unit
  end

  def test_speed
    speed = Class.new(Metric)
    speed.instance_eval do
      self.dimension = Dimension::Vel
      self.default = Unit[:Vel, :SI, :"km/h"]
      self.base = default
    end
    assert m = speed.parse('20 knots', Locale::DK)
    assert_equal 20, m
    assert_same Unit[:Vel, :U, 'knot'], m.unit
    m = m.localize(Locale::US)
    assert_in_delta 23, m, 0.1
    assert_same Unit[:Vel, :US, 'mph'], m.unit
  end

  # All Locale's should have an explicit system ordering for the Autonomy metric that places the Universal system first
  def test_autonomy
    assert m = Autonomy.load(200000)
    assert_same Unit[:L, :U, :M], m.unit
    assert_in_delta 108, m, 0.1
    m = m.localize(Locale::US)
    assert_same Unit[:L, :U, :M], m.unit
  end
end