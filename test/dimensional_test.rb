require 'test/unit'
require 'dimensional'

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
    assert m = EngineDisplacement.parse('5.7l')
    assert_equal 5.7, m
    assert_same Unit[:V, :SI, 'liter'], m.unit
    m = m.change_system(:US)
    assert_in_delta 347, m, 1
    assert_same Unit[:V, :US, 'in3'], m.unit
  end

  def test_mechanical_power
    assert m = MechanicalPower.parse('430hp')
    assert_equal 430, m
    assert_same Unit[:P, :US, :hp], m.unit
    m = m.change_system(:SI)
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
    assert m = speed.parse('20 knots')
    assert_equal 20, m
    assert_same Unit[:Vel, :BA, 'knot'], m.unit
    m = m.change_system(:US)
    assert_in_delta 23, m, 0.1
    assert_same Unit[:Vel, :US, 'mph'], m.unit
  end

  def test_autonomy
    assert m = Autonomy.new(200000, Unit[:L, :SI, :meter])
    assert_same Unit[:L, :SI, :meter], m.unit
    m = m.change_system(:US)
    assert_in_delta 124.3, m, 0.1
    assert_same Unit[:L, :US, :mi], m.unit
  end
end