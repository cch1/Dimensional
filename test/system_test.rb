require 'test/unit'
require 'dimensional/system'

class SystemTest < Test::Unit::TestCase
  include Dimensional

  def teardown
    System.reset!
  end

  def test_create_new_measurement_system
    assert_instance_of System, s = System.new('British Admiralty')
    assert_equal 'British Admiralty', s.name
    assert_nil s.abbreviation
  end
  
  def test_create_new_measurement_system_with_abbreviation
    assert_instance_of System, s = System.new('British Admiralty', 'BA')
    assert_equal 'British Admiralty', s.name
    assert_equal 'BA', s.abbreviation
  end
  
  def test_register_new_measurement_system
    assert_instance_of System, s = System.register('British Admiralty')
    assert_same s, System['British Admiralty']
  end
  
  def test_register_new_measurement_system_with_abbreviation
    assert_instance_of System, s = System.register('British Admiralty', 'BA')
    assert_same s, System['BA']
    assert defined?(System::BA)
    assert_same s, System::BA
  end

  def test_not_raise_exception_when_system_not_found
    assert_nothing_raised do
      System['British Admiralty']
    end
  end
end