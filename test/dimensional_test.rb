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
end