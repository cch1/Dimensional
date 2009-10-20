require 'test/unit'
require 'dimensional/configurator'

class ConfiguratorTest < Test::Unit::TestCase
  include Dimensional

  def setup
    System.register('International System', 'SI')
    System.register('United States Customary', 'US')
    System.register('British Admiralty', 'BA')
    Dimension.register('Length')
    Dimension.register('Area', 'A', {Dimension::L => 2})
    Dimension.register('Mass')
  end

  def teardown
    Dimension.reset!
    System.reset!
    Unit.reset!
    Metric.reset!
  end

  def test_create_configurator
    assert_instance_of Configurator, c = Configurator.new
    assert_nil c.context.dimension
    assert_nil c.context.system
    assert_nil c.context.unit
  end

  def test_start_configurator
    assert Configurator.start
    assert Configurator.start {true}
    assert !Configurator.start {false}
  end

  def test_start_configurator_with_context_args
    assert_same Dimension::L, Configurator.start(:dimension => Dimension::L){context.dimension}
  end

  def test_change_dimension_context_for_duration_of_block
    test_context = self
    Configurator.start do
      dimension(Dimension::L) do
        test_context.assert_equal Dimension::L, context.dimension
        true
      end
      test_context.assert_nil context.dimension
    end
  end
  
  def test_change_system_context_for_duration_of_block
    test_context = self
    Configurator.start do
      system(System::SI) do
        test_context.assert_equal System::SI, context.system
        true
      end
      test_context.assert_nil context.system
    end
  end

  def test_preserve_context_within_block
    test_context = self
    Dimensional::Configurator.start do
      dimension(:L) do
        system(:SI) do
          base('meter') do
            test_context.assert uc = context.unit
            derive('centimeter', 1e-2)
            test_context.assert_same uc, context.unit
          end
        end
      end
    end
  end

  def test_build_base_unit
    Configurator.start(:system => System::SI, :dimension => Dimension::L) do
      base('meter', :detector => /\A(meters?|m)\Z/, :abbreviation => 'm')
    end
    assert_instance_of Unit, u = Unit[Dimension::L, System::SI, 'meter']
    assert_same System::SI, u.system
    assert_same Dimension::L, u.dimension
    assert u.base?
    assert_instance_of Metric, Metric[:L]
  end

  def test_build_derived_unit
    Configurator.start(:system => System::SI, :dimension => Dimension::L) do
      base('meter', :detector => /\A(meters?|m)\Z/, :abbreviation => 'm') do
        derive('centimeter', 1e-2, :detector => /\A(centimeters?|cm)\Z/, :abbreviation => 'cm')
      end
    end
    u0 = Unit[Dimension::L, System::SI, 'meter']
    assert_instance_of Unit, u = Unit[Dimension::L, System::SI, 'centimeter']
    assert_same System::SI, u.system
    assert_same Dimension::L, u.dimension
    assert_same u0, u.base
    assert_equal 1E-2, u.factor
    assert_equal 'cm', u.abbreviation
    assert u.match("centimeters")
  end

  def test_build_aliased_unit
    Configurator.start(:system => System::SI, :dimension => Dimension::L) do
      base('meter', :detector => /\A(meters?|m)\Z/, :abbreviation => 'm') do
        self.alias('decadecimeter')
      end
    end
    u0 = Unit[Dimension::L, System::SI, 'meter']
    assert_instance_of Unit, u = Unit[Dimension::L, System::SI, 'decadecimeter']
    assert_same System::SI, u.system
    assert_same Dimension::L, u.dimension
    assert_same u0, u.base
    assert_equal 1, u.factor
  end

  def test_build_referenced_unit
    Configurator.start(:system => System::SI, :dimension => Dimension::L) do
      base('meter', :detector => /\A(meters?|m)\Z/, :abbreviation => 'm')
      system(:US) do
        reference('yard', Unit[:L, :SI, 'meter'], 0.9144, :detector => /\A(yards?|yds?)\Z/, :abbreviation => 'yd')
      end
    end
    u0 = Unit[Dimension::L, System::SI, 'meter']
    assert_instance_of Unit, u = Unit[Dimension::L, System::US, 'yard']
    assert_equal 0.9144, u.factor
    assert_same u0, u.base
  end

  def test_build_combined_unit
    Configurator.start(:system => System::SI, :dimension => Dimension::L) do
      base('meter', :detector => /\A(meters?|m)\Z/, :abbreviation => 'm')
      system(:US) do
        reference('yard', Unit[:L, :SI, 'meter'], 0.9144, :detector => /\A(yards?|yds?)\Z/, :abbreviation => 'yd')
        dimension(:A) do
          combine('square yard', [Unit[:L, :US, 'yard'], Unit[:L, :US, 'yard']], :detector => //, :abbreviation => 'yd2')
        end
      end
    end
    u1 = Unit[Dimension::L, System::US, 'yard']
    assert_instance_of Unit, u = Unit[:A, :US, 'square yard']
    assert_equal Dimension::A, u.dimension
    assert_equal 0.83612736, u.factor
    assert_equal [u1.base, u1.base], u.base
  end
  
  def test_register_metric_options
    Configurator.start(:system => System::SI, :dimension => Dimension::L) do
      base('meter', :detector => /\A(meters?|m)\Z/, :abbreviation => 'm') do
        prefer(:length_over_all, :precision => 0.01)
      end
    end
    u = Unit[:L, :SI, 'm']
    assert_instance_of Metric, m = Metric[:length_over_all]
    assert_same Metric[:L], m.parent
    assert_equal 0.01, m.preferences(u)[:precision]
  end
end