require 'test/unit'
require 'dimensional'

class DimensionalTest < Test::Unit::TestCase
  include Dimensional

  def setup
    load 'demo.rb'
  end

  def teardown
    Dimension.reset!
    System.reset!
    Unit.reset!
    Metric.reset!
  end

  def test_a_lot
    100.times do
      assert u0 = Unit[:A, :US, 'acre']
      assert 'acre', u0.name
      assert_equal 'acre', u0.name
      assert u1 = Unit[:A, :SI, 'square meter']
      assert_equal u0.base, u1.base
      assert_equal 4046.8564224, u0.factor
      assert_equal 1, u1.factor
      assert_equal 4046.8564224, u0.convert(u1)
      assert_equal 1.0/4046.8564224, u1.convert(u0)
  
      assert metric = Metric[:forestry]
      assert_same Dimension[:A], metric.dimension
  
      assert m0 = Measure.parse("1.0 acre", metric)
      assert_equal 'acre', m0.unit.name

      assert_in_delta 1.0, m0, 0.00001
      assert_same u0, m0.unit
      assert_in_delta 4046.8564224, m0.unit.convert(u1), 0.00001
      assert_in_delta 4046.8564224, u0.convert(u1), 0.00001
      assert_in_delta 4046.8564224, m0 * m0.unit.convert(u1), 0.00001
      
      assert m1 = m0.convert(u1)
      assert_in_delta 4046.8564224, m1, 0.00001
      assert_equal %w(meter meter).map{|name| Unit[:L, :SI, name]}, m1.unit.base
      assert u2 = Unit[:A, :SI, 'hectare']
      assert m2 = m1.convert(u2)
      assert_in_delta 0.40468564224, m2, 0.00001
      assert_equal "0.40468564224ha", m2.to_s
    end
  end
end