require 'test/unit'
require 'dimensional/dimension'

class DimensionTest < Test::Unit::TestCase
  include Dimensional

  def teardown
    Dimension.reset!
  end

  def test_create_new_fundamental_dimension
    assert_instance_of Dimension, d = Dimension.new('Mass')
    assert d.fundamental?
    assert_equal 'Mass', d.name
    assert_equal 'M', d.symbol
    assert_equal Hash.new, d.exponents
  end

  def test_create_new_composite_dimension
    l = Dimension.new('Length')
    assert_instance_of Dimension, a = Dimension.new('Hyperspace', 'H4', {l => 4})
    assert !a.fundamental?
    assert a.exponents.has_key?(l)
    assert_equal 4, a.exponents[l]
  end

  def test_register_new_dimension
    assert d = Dimension.register('Length')
    assert_instance_of Dimension, d
    assert_same d, Dimension['Length']
    assert_same d, Dimension['L']
    assert defined?(Dimension::L)
    assert_same d, Dimension::L
  end

  def test_register_new_dimension_with_alternate_symbol
    assert d = Dimension.register('Electric Charge', 'Q')
    assert_instance_of Dimension, d
    assert_same d, Dimension['Electric Charge']
    assert_same d, Dimension['Q']
    assert defined?(Dimension::Q)
    assert_same d, Dimension::Q
  end

  def test_register_new_dimension_with_symbol_that_is_not_a_valid_constant
    assert d = Dimension.register('Temperature', 'Θ')
    assert_instance_of Dimension, d
    assert_same d, Dimension['Temperature']
    assert_same d, Dimension['Θ']
  end
  
  def test_return_nil_on_nil_lookup
    assert_nil Dimension[nil]
  end
end