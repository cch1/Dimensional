# encoding: UTF-8
require 'helper'

class UnitTest < Test::Unit::TestCase
  include Dimensional

  def setup
    System.register('International System of Units', 'SI')
    System.register('United States Customary', 'US')
    System.register('British Admiralty', 'BA')
    Dimension.register('Length')
    Dimension.register('Mass')
    Dimension.register('Force')
    Dimension.register('Area', 'A', {Dimension::L => 4})
  end

  def teardown
    Dimension.reset!
    System.reset!
    Unit.reset!
  end

  def test_create_new_base_unit
    assert_instance_of Unit, u = Unit.new('cable', System::BA, Dimension::L, {})
    assert_same System::BA, u.system
    assert_same Dimension::L, u.dimension
    assert u.base?
    assert_equal({u => 1}, u.base)
    assert_kind_of Rational, u.base[u]
    assert_equal 1, u.factor
    assert_kind_of Rational, u.factor
  end

  def test_enumerability
    u = Unit.register('each', System::BA, nil, {})
    assert Unit.to_a.include?(u)
  end

  def test_create_new_dimensionless_unit
    assert_instance_of Unit, u = Unit.new('each', System::BA, nil, {})
    assert_nil u.dimension
  end

  def test_create_new_derived_unit
    cable = Unit.new('cable', System::BA, Dimension::L, {})
    assert_instance_of Unit, u = Unit.new('fathom', System['BA'], Dimension['L'], :reference_factor => 1E-1, :reference_units => {cable => 1})
    assert !u.base?
    t = u.base
    assert_equal({cable => 1}, t)
    assert_equal 1E-1, u.factor
  end

  def test_create_new_combined_unit
    meter = Unit.new('meter', System::SI, Dimension::L, {})
    assert_instance_of Unit, u = Unit.new('square meter', System::SI, Dimension::L, :reference_factor => 1, :reference_units => {meter => 2})
    assert !u.base?
    assert_equal({meter => 2}, u.base)
    assert_equal 1, u.factor
  end

  def test_create_new_combined_with_derived_unit_and_big_exponents
    meter = Unit.new('meter', System::SI, Dimension::L, {})
    assert_instance_of Unit, yard = Unit.new('yard', System::US, Dimension::L, :reference_factor => 0.9144, :reference_units => {meter => 1})
    assert_instance_of Unit, yard2 = Unit.new('square yard', System::SI, Dimension::A, :reference_factor => 1, :reference_units => {yard => 2})
    assert !yard2.base?
    assert_equal({meter => 2}, yard2.base)
    assert_equal 0.83612736, yard2.factor
  end

  def test_regsiter_new_unit
    assert_instance_of Unit, u = Unit.register('fathom', System::BA, Dimension::L, {:abbreviation => 'fm'})
    assert_same u, Unit[Dimension::L, System::BA, 'fathom']
    assert_same u, Unit[Dimension::L, System::BA, 'fm']
  end

  def test_regsiter_new_dimensionless_unit
    assert_instance_of Unit, u = Unit.register('each', System::BA, nil, {:abbreviation => 'ea'})
    assert_same u, Unit[nil, System::BA, 'each']
    assert_same u, Unit[nil, System::BA, 'ea']
  end

  def test_lookup_unit_with_symbols
    u = Unit.register('fathom', System::BA, Dimension::L, {:abbreviation => 'fm'})
    assert_same u, Unit[:L, :BA, 'fathom']
  end

  def test_lookup_failure
    assert_raises ArgumentError do
      Unit[:L, :SI, 'fathom']
    end
    assert_raises ArgumentError do
      Unit[:M, :BA, 'fathom']
    end
    assert_raises ArgumentError do
      Unit[:L, :BA, 'somethingelse']
    end
  end

  def test_convert
    cable = Unit.new('cable', System::BA, Dimension::L, {})
    fathom = Unit.new('fathom', System::BA, Dimension::L, :reference_factor => 1E-1, :reference_unit => cable)
    assert_equal 10, cable.convert(fathom)
    assert_equal 1E-1, fathom.convert(cable)
    assert_equal 1, fathom.convert(fathom)
  end

  def test_identify_commensurable_units
    u0 = Unit.new('mile', System::BA, Dimension::L, :abbreviation => 'nm')
    u1 = Unit.new('cable', System::BA, Dimension::L, :reference_factor => 1E-1, :reference_unit => u0)
    u2 = Unit.new('ton', System::BA, Dimension::M, :abbreviation => 't')
    assert u0.commensurable?(u1)
    assert !u0.commensurable?(u2)
  end

  def test_identify_commensurable_composed_units
    u0 = Unit.new('mile', System::BA, Dimension::L, :abbreviation => 'nm')
    u1 = Unit.new('cable', System::BA, Dimension::L, :reference_factor => 1E-1, :reference_unit => u0)
    u2 = Unit.new('ton', System::BA, Dimension::M, :abbreviation => 't')
    assert u0.commensurable?(u1)
    assert !u0.commensurable?(u2)
  end

  def test_identity
    u0 = Unit.new('mile', System::BA, Dimension::L)
    u1 = Unit.new('mile', System::BA, Dimension::L)
    u2 = Unit.new('statute mile', System::BA, Dimension::L)
    # u0 and u1 are effectively identical and should collide in hashes
    assert_same u0.hash, u1.hash
    assert u0.eql?(u1)
    # u0 and u2 are distinct and should not collide in hashes
    assert_not_same u0.hash, u2.hash
    assert !u0.eql?(u2)
  end

  def test_equality
    u0 = Unit.new('mile', System::BA, Dimension::L)
    u1 = Unit.new('sea mile', System::BA, Dimension::L, :reference_factor => 1, :reference_units => {u0 => 1})
    u2 = Unit.new('mile', System::BA, Dimension::L, :reference_factor => 0.93, :reference_units => {u0 => 1}) # modern approximation
    # u0 and u1 have the same value but different identities
    assert_equal u0, u1
    # u0 and u2 have the same identity but different values
    assert_not_equal u0, u2
  end

  def test_default_detector
    u0 = Unit.new('mile', System::BA, Dimension::L, :abbreviation => 'nm')
    assert_match u0.detector, 'mile'
    assert_match u0.detector, 'nm'
  end

  def test_default_format
    u0 = Unit.new('mile', System::BA, Dimension::L, :abbreviation => 'nm')
    assert_match /%.*s/, u0.format
    assert_match /%.*U/i, u0.format
  end

  def test_default_preference
    u0 = Unit.new('mile', System::BA, Dimension::L, :abbreviation => 'nm')
    assert_equal 0, u0.preference
  end
end