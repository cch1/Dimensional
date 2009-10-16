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
      assert m0 = Measure.parse("1 acre", Metric[:forestry])
      assert u2 = Unit[:A, :SI, 'hectare']
      assert m2 = m0.convert(u2)
      assert_in_delta 0.40468564224, m2, 0.00001
      assert_equal "0.4047ha", m2.to_s
    end
  end
end