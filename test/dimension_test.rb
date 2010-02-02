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
    assert_equal Hash.new, d.basis
  end

  def test_create_new_composite_dimension
    l = Dimension.new('Length')
    assert_instance_of Dimension, a = Dimension.new('Hyperspace', 'H4', {l => 4})
    assert !a.fundamental?
    assert a.basis.has_key?(l)
    assert_equal 4, a.basis[l]
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

  def test_identity
    d0 = Dimension.new("Length", 'L')
    d1 = Dimension.new("Length", 'l')
    d2 = Dimension.new("Temperature", 'Q')
    # d0 and d1 are effectively identical and should collide in hashes
    assert_same d0.hash, d1.hash
    assert d0.eql?(d1)
    # d0 and d2 are distinct and should not collide in hashes
    assert_not_same d0.hash, d2.hash
    assert !d0.eql?(d2)
  end

  def test_equality
    length = Dimension.new("Length")
    mass = Dimension.new("Mass")
    time = Dimension.new("Time")
    d0 = Dimension.new("Weight", nil, {mass => 1, length => 1, time => -2})
    d1 = Dimension.new("Force", nil, {mass => 1, length => 1, time => -2})
    d2 = Dimension.new("Weight", nil, {mass => 1}) # For the physics-challenged out there, pay attention!
    # d0 and d1 have the same value but different identities
    assert_equal d0, d1
    # d0 and d3 have the same identity but different values
    assert_not_equal d0, d2
  end
end