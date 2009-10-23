require 'test/unit'
require 'dimensional/metric'
require 'dimensional/unit'
require 'rational'

class MetricTest < Test::Unit::TestCase
  include Dimensional

  def setup
    Dimension.register('Length')
    Dimension.register('Mass')
    Dimension.register('Force')
    System.register('British Admiralty', 'BA')
    System.register('United States Customary', 'US')
    cable = Unit.register('cable', System::BA, Dimension::L, {})
    fathom = Unit.register('fathom', System::BA, Dimension::L, {:reference_unit => cable, :reference_factor => Rational(1,10)})
    yard = Unit.register('yard', System::BA, Dimension::L, {:reference_unit => fathom, :reference_factor => Rational(1,6)})
    Unit.register('foot', System::BA, Dimension::L, {:reference_unit => yard, :reference_factor => Rational(1,3)})
    Unit.register('foot', System::US, Dimension::L, {:reference_unit => yard, :reference_factor => Rational(1,3)})
    Unit.register('pound', System::US, Dimension::M)
    Unit.register('pound', System::US, Dimension::F)
  end

  def teardown
    Dimension.reset!
    System.reset!
    Unit.reset!
    Metric.reset!
  end

  def test_create
    assert_instance_of Metric, m = Metric.new('draft', Dimension::L)
    assert_same Dimension::L, m.dimension
    assert_equal 'draft', m.name
  end
  
  def test_register
    assert_instance_of Metric, m = Metric.register('draft', Dimension::L)
    assert_same m, Metric[:draft]
  end
  
  def test_register_metric_with_parent
    parent = Metric.register('L', Dimension::L)
    child = Metric.register('depth', nil, parent)
    assert_same parent, child.parent
  end
  
  def test_register_dimensionless_metric
    assert_instance_of Metric, m = Metric.register('population', nil)
    assert_same m, Metric[:population]
  end
  
  def test_register_default_dimensionless_metric
    assert_instance_of Metric, m = Metric.register(nil, nil)
    assert_same m, Metric[nil]
  end
  
  def test_unit_preferences
    length = Metric.register('L', Dimension::L)
    draft = Metric.register('draft', Dimension::L, length)
    foot = Unit[Dimension::L, System::BA, 'foot']
    length.prefer(foot, {:detector => /(foot|ft)?s/})
    draft.prefer(foot, {:precision => Rational(1, 12)})
    assert_instance_of Hash, draft.preferences(foot)
    assert_equal Rational(1,12), draft.preferences(foot)[:precision]
    assert_equal /(foot|ft)?s/, draft.preferences(foot)[:detector]
  end
  
  def test_unit_membership
    length = Metric.register('L', Dimension::L)
    mass = Metric.register('M', Dimension::M)
    depth = Metric.register('depth', Dimension::L, length)
    foot = Unit[:L, :BA, 'foot']
    fathom = Unit[:L, :BA, 'fathom']
    pound = Unit[:M, :US, 'pound']
    length.prefer(foot)
    length.prefer(fathom)
    depth.prefer(fathom)
    mass.prefer(pound)
    assert_same fathom, depth.units.first # Units should be ordered with preferred units first...
    assert_same foot, depth.units.last  # ...followed by remaining units from parent.
    assert_equal 2, depth.units.size # Units should be de-duped with parent
  end

  def test_enumerate
    length = Metric.register('L', Dimension::L)
    assert length.to_enum.kind_of?(Enumerable::Enumerator)
    assert_respond_to length, :map
  end
  
  def test_preferences_query_does_not_modify_preferences
    draft = Metric.register('draft', Dimension::L)
    foot = Unit[:L, :BA, 'foot']
    p0 = draft.preference(foot)
    draft.preferences(foot)
    p1 = draft.preference(foot)
    assert_equal p0, p1
  end
end