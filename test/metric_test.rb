require 'helper'
require 'rational'

class MetricTest < Test::Unit::TestCase
  include Dimensional

  def setup
    Dimension.register('Length')
    Dimension.register('Mass')
    Dimension.register('Force')
    System.register('British Admiralty', 'BA')
    System.register('United States Customary', 'US')
    System.register('International System of Units', 'SI')
    # Length Units - SI
    @meter = Unit.register('meter', System::SI, Dimension::L, {:abbreviation => 'm'})
    @kilometer = Unit.register('kilometer', System::SI, Dimension::L, {:reference_units => {@meter => 1}, :reference_factor => 1000, :abbreviation => 'km'})
    @centimeter = Unit.register('centimeter', System::SI, Dimension::L, {:reference_units => {@meter => 1}, :reference_factor => Rational(1,100), :abbreviation => 'cm'})
    @international_nautical_mile = Unit.register('nautical mile', System::SI, Dimension::L, {:reference_units => {@meter => 1}, :reference_factor => Rational(1852,1), :abbreviation => 'M', :preference => -3})
    # Length Units - US
    @yard_us = Unit.register('yard', System::US, Dimension::L, {:reference_units => {@meter => 1}, :reference_factor => 0.9144, :abbreviation => 'yd'})
    @foot_us = Unit.register('foot', System::US, Dimension::L, {:reference_units => {@yard_us => 1}, :reference_factor => Rational(1,3), :abbreviation => 'ft'})
    @mile_us = Unit.register('mile', System::US, Dimension::L, {:reference_units => {@foot_us => 1}, :reference_factor => 5280, :abbreviation => 'mi'})
    @inch_us = Unit.register('inch', System::US, Dimension::L, {:reference_units => {@foot_us => 1}, :reference_factor => Rational(1,12), :abbreviation => 'in'})
    # Length Units - BA
    @nautical_mile = Unit.register('mile', System::BA, Dimension::L, {:abbreviation => 'nm'})
    @cable = Unit.register('cable', System::BA, Dimension::L, {:reference_units => {@nautical_mile => 1}, :reference_factor => Rational(1,10)})
    @fathom = Unit.register('fathom', System::BA, Dimension::L, {:reference_units => {@cable => 1}, :reference_factor => Rational(1,10), :abbreviation => 'fm'})
    @yard_ba = Unit.register('yard', System::BA, Dimension::L, {:reference_units => {@fathom => 1}, :reference_factor => Rational(1,6), :abbreviation => 'yd'})
    @foot_ba = Unit.register('foot', System::BA, Dimension::L, {:reference_units => {@yard_ba => 1}, :reference_factor => Rational(1,3), :abbreviation => 'ft'})
    @inch_ba = Unit.register('inch', System::BA, Dimension::L, {:reference_units => {@foot_ba => 1}, :reference_factor => Rational(1,12), :abbreviation => 'in'})
    # Mass Units
    @pound_mass = Unit.register('pound', System::US, Dimension::M, {:abbreviation => 'lb'})
    # Force Units
    @pound_force = Unit.register('pound', System::US, Dimension::F, {:abbreviation => 'ft'})
    # Dimensionless Units
    @each = Unit.register('each', System::US, nil, {:abbreviation => 'ea'})
    @dozen = Unit.register('dozen', System::US, nil, {:reference_units => {@each => 0}, :reference_factor => 12, :abbreviation => 'dz'})
    Locale.default.systems = [System::SI, System::US, System::BA]
    Locale::US.systems = [System::US, System::SI, System::BA]
    Locale::BA.systems = [System::BA]
  end

  def teardown
    Dimension.reset!
    System.reset!
    Unit.reset!
    Locale.reset!
  end

  def test_register_conflicting_unit
    displacement = Class.new(Metric)
    displacement.dimension = Dimension::M
    assert_raises RuntimeError do
      displacement.configure(@pound_force)
    end
  end

  def test_create_new_measure
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    assert m = depth.new(20, @fathom)
    assert_equal 20, m
    assert_equal @fathom, m.unit
  end

  def test_create_new_metric_with_default_unit
    frontage = Class.new(Metric)
    frontage.dimension = Dimension::L
    frontage.default = Unit[:L, :US, :yard]
    assert m = frontage.new(200)
    assert_equal 200, m
    assert_equal @yard_us, m.unit
  end

  def test_load_metric
    range = Class.new(Metric)
    range.instance_eval do
      self.dimension = Dimension::L
      self.base = Unit[:L, :SI, :m]
      configure Unit[:L, :SI, :M], :preference => 0
    end
    assert r = range.load(200000)
    assert_in_delta(108, r, 0.1)
    assert_same @international_nautical_mile, r.unit
  end

  def test_find_unit
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    assert_same @foot_ba, depth.find_unit('foot', Locale::BA)
    assert_same @foot_us, depth.find_unit('foot', Locale::US)
  end

  def test_scanner
    assert_equal [%w(3 m)], "3m".scan(Metric::NUMERIC_REGEXP)
    assert_equal [%w(3 m)], "3 m".scan(Metric::NUMERIC_REGEXP)
    assert_equal [%w(.3 m)], ".3m".scan(Metric::NUMERIC_REGEXP)
    assert_equal [%w(0.3 m)], "0.3m".scan(Metric::NUMERIC_REGEXP)
    assert_equal [%w(01.32 m)], "01.32m".scan(Metric::NUMERIC_REGEXP)
    assert_equal [%w(6 '), %w(4 ")], "6'4\"".scan(Metric::NUMERIC_REGEXP)
    assert_equal [%w(6 feet), %w(4 inches)], "6 feet 4 inches".scan(Metric::NUMERIC_REGEXP)
    assert_equal [["1.32", "nautical miles"]], "1.32 nautical miles".scan(Metric::NUMERIC_REGEXP)
#    assert_equal [%w(.3 m3)], ".3m3".scan(Metric::NUMERIC_REGEXP)
  end

  def test_parse
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    assert m = depth.parse("15ft", Locale::BA)
    assert_same @foot_ba, m.unit
    assert_equal 15, m
  end

  def test_parse_with_whitespace
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    m = depth.parse("15 ft", Locale::BA)
    assert_same @foot_ba, m.unit
    assert_equal 15, m
  end

  def test_parse_with_multiword_unit
    range = Class.new(Metric)
    range.dimension = Dimension::L
    m = range.parse("15 nautical miles")
    assert_same @international_nautical_mile, m.unit
    assert_equal 15, m
  end

  def test_parse_compound
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    d = depth.parse("15ft11in", Locale::US)
    assert_in_delta(15 + Rational(11, 12), d, 0.000001)
    assert_same @foot_us, d.unit
  end

  def test_parse_compound_with_whitespace
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    d = depth.parse("1 ft 11 in", Locale::US)
    assert_same d.unit, @foot_us
    assert_in_delta(1 + Rational(11, 12).to_f, d, 0.000001)
    assert_same @foot_us, d.unit
  end

  def test_raise_on_parse_of_mixed_compound
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    assert_raises ArgumentError do
      depth.parse("1 foot 11cm", Locale::US)
    end
  end

  def test_parse_with_default_unit
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    depth.default = @meter
    assert_instance_of depth, m = depth.parse("10", Locale::US)
    assert_equal @meter, m.unit
  end

  def test_parse_dimensionless_units
    count = Class.new(Metric)
    assert m = count.parse('2 dozen')
    assert_instance_of count, m
    assert_equal 2, m
    assert_equal @dozen, m.unit
    assert_equal 12, m.unit.factor
    assert_nil m.unit.dimension
  end

  def test_to_f
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    d = depth.parse("1.85m", Locale::SI)
    assert_instance_of Float, d.to_f
  end

  def test_to_i
    count = Class.new(Metric)
    d = count.parse("1 each")
    assert_instance_of Fixnum, d.to_i
  end

  def test_convert
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    new = depth.new(1, @cable).convert(@fathom)
    assert_in_delta(10, new, 0.000001)
    assert_same @fathom, new.unit
  end

  def test_convert_with_fractional_factor
    range = Class.new(Metric)
    range.dimension = Dimension::L
    new = range.new(100000, @meter).convert(@kilometer)
    assert_in_delta(100, new, 0.000001)
    assert_same @kilometer, new.unit
  end

  def test_identity_conversion
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    old_value = depth.new(12, @cable)
    new_value = old_value.convert(@cable)
    assert_equal old_value, new_value
  end

  # These system-conversion tests rely on very specific constants in the heuristics of #change_system
  def test_change_system_yd
    range = Class.new(Metric)
    range.dimension = Dimension::L
    m0 = range.new(1, @yard_us)
    assert m1 = m0.change_system(:SI)
    assert_same @meter, m1.unit
  end

  def test_change_system_with_oom_dominance
    width = Class.new(Metric)
    width.dimension = Dimension::L
    m0 = width.new(1, @inch_us)
    assert m1 = m0.change_system(:SI)
    assert_same @centimeter, m1.unit
  end

  def test_change_system_ft
    range = Class.new(Metric)
    range.dimension = Dimension::L
    m0 = range.new(1, @foot_us)
    assert m1 = m0.change_system(:SI)
    assert_same @centimeter, m1.unit
  end

  def test_change_system_mile
    range = Class.new(Metric)
    range.dimension = Dimension::L
    m0 = range.new(1, @mile_us)
    assert m1 = m0.change_system(:SI)
    assert_same @kilometer, m1.unit
  end

  # These preferred tests rely on very specific constants in the heuristics of #prefer
  def test_preferred_unit_with_only_oom
    range = Class.new(Metric)
    range.instance_eval do
      self.dimension = Dimension::L
    end
    m0 = range.new(100000, @meter)
    assert m1 = m0.preferred(Locale::FR)
    assert_same @kilometer, m1.unit
  end

  # These preferred tests rely on very specific constants in the heuristics of #prefer
  def test_preferred_unit_with_oom_and_preference
    range = Class.new(Metric)
    range.instance_eval do
      self.dimension = Dimension::L
      configure Unit[:L, :SI, :meter], {:preference => 3.01}
    end
    m0 = range.new(100000, Unit[:L, :SI, :meter])
    assert m1 = m0.preferred
    assert_same @meter, m1.unit
  end

  def test_convert_to_base
    range = Class.new(Metric)
    range.dimension = Dimension::L
    range.base = @nautical_mile
    b = range.new(1, @fathom).base
    assert_in_delta(1e-2, b, 0.000001)
    assert_same @nautical_mile, b.unit
  end

  def test_stringify_with_abbreviation
    range = Class.new(Metric)
    range.dimension = Dimension::L
    assert_equal "1.85 nm", range.parse('1.85 miles', Locale::BA).to_s
  end

  def test_parse_gibberish_as_nil
    beam = Class.new(Metric)
    beam.dimension = Dimension::L
    assert_nil beam.parse("gibberish", Locale::US)
  end

  def test_format_output
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    m = depth.parse("15ft3in", Locale::BA)
    assert_equal "15.25 (ft)", m.strfmeasure("%4.2f (%U)")
  end

  def test_format_output_with_multiple_substitutions
    depth = Class.new(Metric)
    depth.dimension = Dimension::L
    m = depth.parse("15ft4in", Locale::BA)
    assert_equal "15.33 (ft)\t%\t<15.3333333ft>", m.strfmeasure("%4.2f (%U)\t%%\t<%10.7f%U>")
  end

  def test_precision_recognition
    distance = Class.new(Metric)
    distance.dimension = Dimension::L
    distance.configure(@nautical_mile, :precision => -2)
    assert_equal "1.8600nm", distance.parse('1.8565454 nm', Locale::BA).strfmeasure("%.4f%U")
    assert_equal "1.86", distance.parse('1.8565454 nm', Locale::BA).strfmeasure("%s")
  end
end