# encoding: UTF-8
require "helper"

class LocaleTest < Test::Unit::TestCase
  include Dimensional

  def setup
    System.register('British Imperial', 'Imp')
    System.register('United States Customary', 'US')
    System.register('International System of Units', 'SI')
    System.register('International Standards', 'Std')
  end

  def teardown
    System.reset!
    Locale.reset!
  end

  def test_default_locale
    assert_kind_of Locale, d = Locale.default
    assert_kind_of Array, d.systems
    assert d.systems.empty?
  end

  def test_create
    default_systems = [System::US, System::SI, System::Std]
    assert us = Locale.new(:US, default_systems)
    assert_equal default_systems, us.systems
    assert_equal 'US', us.to_s
  end

  def test_register
    assert_kind_of Locale, us = Locale.register(:US)
    assert_same us, Locale::US
    assert_equal 'US', us.to_s
  end

  def test_auto_constant_defaults
    default_default_systems = [System::SI, System::Std, System::US, System::Imp]
    Locale.default.systems = default_default_systems
    assert_kind_of Locale, ca = Locale::CA
    assert_equal default_default_systems, ca.systems
  end

  def test_auto_constant_defaults_for_all_metrics
    default_default_systems = [System::SI, System::Std, System::US, System::Imp]
    us_default_systems = [System::Std, System::US, System::SI, System::Imp]
    Locale.default.systems = default_default_systems
    assert_kind_of Locale, us = Locale::US
    us.systems = us_default_systems
    assert_equal us_default_systems, us.systems
  end

  def test_auto_constant_defaults_are_independent
    default_default_systems = [System::SI, System::Std, System::US, System::Imp]
    default_ca_systems = [System::SI, System::Std, System::Imp, System::US]
    default_us_systems = [System::US, System::Std, System::SI, System::Imp]
    Locale.default.systems = default_default_systems
    Locale::CA.systems = default_ca_systems
    Locale::US.systems.replace(default_us_systems)
    assert_equal default_default_systems, Locale::BE.systems
    assert_equal default_us_systems, Locale::US.systems
    assert_equal default_ca_systems, Locale::CA.systems
  end
end