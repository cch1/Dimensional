require 'test/unit'
require 'dimensional/measure'
require 'dimensional/configurator'
require 'rational'

class MeasureTest < Test::Unit::TestCase
  include Dimensional

  def setup
    System.register('International System of Units', 'SI')
    System.register('United States Customary Units', 'US')
    System.register('British Admiralty', 'BA')
    
    Dimension.register('Length')
    Dimension.register('Mass')
    
    Metric.register('length', :L)

    Configurator.start do
      dimension(:L) do
        system(:SI) do
          base('meter', :detector => /\A(meters?|m)\Z/, :abbreviation => 'm') do
            prefer(:length_over_all, :precision => 0.01)
            derive('centimeter', 1e-2, :detector => /\A(centimeters?|cm)\Z/, :abbreviation => 'cm')
            derive('kilometer', 1e3, :detector => /\A(kilometers?|km)\Z/, :abbreviation => 'km')
          end
        end
        system(:US) do # As of 1 July 1959 (http://en.wikipedia.org/wiki/United_States_customary_units#Units_of_length)
          reference('yard', Unit[:L, :SI, 'meter'], 0.9144, :detector => /\A(yards?|yds?)\Z/, :abbreviation => 'yd') do
            derive('foot', Rational(1,3), :detector => /\A(foot|feet|ft|')\Z/, :abbreviation => "ft", :format => "%p'") do
              prefer(:length_over_all, :precision => Rational(1, 12))
              derive('inch', Rational(1,12), :detector => /\A(inch|inches|in|")\Z/, :abbreviation =>"in", :format => "%p\"")          
            end
            derive('furlong', 220, :detector => /\A(furlongs?)\Z/) do
              derive('mile', 8, :detector => /\Amiles?\Z/, :abbreviation => 'mi')
            end
          end
        end
        system(:BA) do
          base('mile', :detector => /\A(miles?|nm|nmi)\Z/, :abbreviation => 'nm') do
            prefer(:distance, :precision => -2)
            derive('cable', Rational(1,10), :detector => /\A(cables?|cbls?)\Z/) do
              derive('fathom', Rational(1,10), :detector => /\A(fathoms?|fms?)\Z/, :abbreviation => 'fm') do
                derive('yard', Rational(1,6), :detector => /\A(yards?|yds?)\Z/, :abbreviation => 'yd') do
                  derive('foot', Rational(1,3), :detector => /\A(foot|feet|ft|')\Z/, :abbreviation => "ft") do
                    prefer(:length_over_all, :precision => Rational(1, 12))
                    derive('inch', Rational(1,12), :detector => /\A(inch|inches|in|")\Z/, :abbreviation => "in")
                  end
                end
              end
            end
          end           
        end
      end
      dimension(:M) do
        system(:SI) do
          base('kilogram', :detector => /\A(kilograms?|kg)\Z/, :abbreviation => 'kg') do
            derive('tonne', 1000, :detector => /\A(tonnes?)\Z/, :abbreviation => 't') # metric ton
            derive('gram', Rational(1, 1000), :detector => /\A(grams?|g)\Z/, :abbreviation => 'g')
          end
        end
      end
      # Dimensionless Units
      base('each', :abbreviation => 'ea') do
        derive('dozen', 12, :abbreviation => 'dz')
      end
    end
  end

  def teardown
    Dimension.reset!
    System.reset!
    Unit.reset!
    Metric.reset!
  end

  def test_create_new_measure
    u = Unit[:L, :BA, 'mile']
    assert m = Measure.new(3000, u, :length)
    assert_equal 3000, m
    assert_equal u, m.unit
    assert_same Metric[:length], m.metric
  end

  def test_to_f
    d = Measure.parse("1.85m", :L, :SI)
    assert_instance_of Float, d.to_f
  end

  def test_to_i
    d = Measure.parse("1 each", Metric[nil])
    assert_instance_of Fixnum, d.to_i
  end

  def test_to_native
    d = Measure.parse("1 each", Metric[nil])
    assert_instance_of Fixnum, d.native
  end

  def test_convert
    old_unit = Unit[:L, :BA, 'cable']
    new_unit = Unit[:L, :BA, 'fathom']
    new = Measure.new(1, old_unit).convert(new_unit)
    assert_in_delta(10, new, 0.000001)
    assert_same new_unit, new.unit
  end

  def test_do_identity_conversion
    old_unit = Unit[:L, :BA, 'cable']
    new_unit = old_unit
    old_value = Measure.new(12, old_unit)
    new_value = old_value.convert(new_unit)
    assert_equal old_value, new_value
  end

  def test_return_base
    u = Unit[:L, :BA, 'fathom']
    b = Measure.new(1, u).base
    assert_in_delta(1e-2, b, 0.000001)
    assert_same u.base, b.unit
  end

  def test_parse
    assert m = Measure.parse("15'", :L, :BA)
    assert_same Unit[:L, :BA, 'foot'], m.unit
    assert_equal 15, m
  end
  
  def test_parse_with_whitespace
    m = Measure.parse("15 feet", :L, :BA)
    assert_same Unit[:L, :BA, 'foot'], m.unit
    assert_equal 15, m
  end

  def test_parse_compound
    d = Measure.parse("15'11\"", :L, :US)
    assert_in_delta(15 + Rational(11, 12), d, 0.000001)
  end

  def test_parse_compound_with_whitespace
    d = Measure.parse("1 foot 11 inches", :L, :US)
    assert_same d.unit, Unit[:L, :US, 'foot']
    assert_in_delta(1 + Rational(11, 12).to_f, d, 0.000001)
  end

  def test_raise_on_parse_of_mixed_compound
    assert_raises ArgumentError do
      Measure.parse("1 foot 11cm", :L)
    end
  end

  def test_parse_with_default_unit
    metric = Metric[:L]
    du = metric.units.first
    assert_instance_of Measure, m = Measure.parse("10", :L) 
    assert_equal du, m.unit
  end

  def test_parse_dimensionless_units
    assert m = Measure.parse('2 dozen', nil)
    assert_instance_of Measure, m
    assert_equal 2, m
    assert_equal Unit[nil, nil, 'dozen'], m.unit
    assert_equal 12, m.unit.factor
    assert_nil m.unit.dimension
  end
  
  def test_stringify_with_abbreviation
    assert_equal "1.85nm", Measure.parse('1.85 miles', :L, :BA).to_s
  end

  def test_parse_gibberish_as_nil
    assert_nil Measure.parse("gibberish", :L)
  end
  
  def test_format_output
    m = Measure.parse("15'3\"", :L, :BA)
    assert_equal "15.25 (ft)", m.strfmeasure("%4.2f (%U)")
  end

  def test_precision_recognition
    assert_equal "1.8600nm", Measure.parse('1.8565454 miles', :distance, :BA).strfmeasure("%.4f%U")
    assert_equal "1.86", Measure.parse('1.8565454 miles', :distance, :BA).strfmeasure("%s")
  end
end