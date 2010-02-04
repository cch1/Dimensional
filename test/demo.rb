require 'dimensional/configurator'
require 'rational'
include Dimensional

# Define fundamental dimensions and composite dimensions
# Reference: http://en.wikipedia.org/wiki/Dimensional_Analysis
Dimension.register('Length')
Dimension.register('Mass')
Dimension.register('Time')
Dimension.register('Temperature', 'Θ')
Dimension.register('Electric Charge', 'Q')
Dimension.register('Area', 'A', {Dimension::L => 2})
Dimension.register('Volume', 'V', {Dimension::L => 3})
Dimension.register('Velocity', 'Vel', {Dimension::L => 1, Dimension::T => -1})
Dimension.register('Acceleration', 'Acc', {Dimension::L => 1, Dimension::T => -2})
Dimension.register('Force', 'F', {Dimension::M => 1, Dimension::L => 1, Dimension::T => -2})
#Dimension.register('Torque', 'τ', {Dimension::M => 1, Dimension::L => 2, Dimension::T => -2}) # equivalent to Energy
Dimension.register('Energy', 'E', {Dimension::M => 1, Dimension::L => 2, Dimension::T => -2}) # a.k.a. work
Dimension.register('Power', 'P', {Dimension::M => 1, Dimension::L => 2, Dimension::T => -3})

# Define common Systems of Measurement
System.register('SI - International System (kg, tonne, m)', 'SI')
System.register('US Customary (lbs, ton, ft)', 'US')  # http://en.wikipedia.org/wiki/United_States_customary_units
System.register('US Customary Troy (oz)', 'USt')  # http://en.wikipedia.org/wiki/United_States_customary_units
System.register('British Imperial (lbs, ton, ft)', 'Imp')  # http://en.wikipedia.org/wiki/Imperial_units
System.register('British Admiralty', 'BA')
System.register('Foot-Pound-Second', 'FPS') #http://en.wikipedia.org/wiki/Foot-pound-second_system

Configurator.start do
  dimension(:L) do
    system(:SI) do
      base('meter', 'm', :detector => /\A(met(er|re)s?|m)\Z/) do
        derive('decimeter', 'dm', Rational(1, 10), :detector => /\A(decimet(er|re)s?|dm)\Z/, :preference => 0.5)
        derive('centimeter', 'cm', Rational(1, 100), :detector => /\A(centimet(er|re)s?|cm)\Z/)
        derive('decameter', 'km', 10, :detector => /\A(de(c|k)amet(er|re)s?|dam)\Z/)
        derive('kilometer', 'km', 1000, :detector => /\A(kilomet(er|re)s?|km)\Z/)
        derive('nautical mile', 'M', 1852, :detector => /\A(nautical miles?|NMs?|nmis?)\Z/)
      end
    end
    system(:US) do # As of 1 July 1959 (http://en.wikipedia.org/wiki/United_States_customary_units#Units_of_length)
      reference('yard', 'yd', Unit[:L, :SI, 'meter'], 0.9144, :detector => /\A(yards?|yds?)\Z/) do
        derive('foot', 'ft', Rational(1,3), :detector => /\A(foot|feet|ft|')\Z/, :format => "%p'") do
          derive('inch', 'in', Rational(1,12), :detector => /\A(inch|inches|in|")\Z/, :format => "%p\"")
        end
        derive('furlong', nil, 220, :detector => /\A(furlongs?)\Z/) do
          derive('mile', 'mi', 8, :detector => /\Amiles?\Z/)
        end
      end
    end
    system(:Imp) do
      reference('yard', 'yd', Dimensional::Unit[:L, :SI, 'meter'], 0.9144, :detector => /\A(yards?|yds?)\Z/) do
        derive('foot', 'ft', Rational(1,3), :detector => /\A(foot|feet|ft|')\Z/, :format => "%p'") do
          derive('inch', 'in', Rational(1,12), :detector => /\A(inch|inches|in|")\Z/, :format => "%p\"")
        end
        derive('furlong', nil, 220, :detector => /\A(furlongs?)\Z/) do
          derive('mile', 'mi', 8, :detector => /\Amiles?\Z/)
        end
      end
    end
    system(:BA) do
      # The nautical mile was historically defined as the length of one minute of arc of latitude along the (current) meridian.
      # That historical definition is thus not a true length standard.  A precise translation of that definition into current units
      # results in an approximation of 1852.216m.  Note that this approximation is very different from the formally defined
      # "international nautical mile."  Reference:
      # http://en.wikipedia.org/wiki/Nautical_mile#Conversions_to_other_units
      reference('mile', 'nm', Dimensional::Unit[:L, :SI, 'meter'], 1852.216, :detector => /\A((nautical )?mile|nm|nmi)\Z/) do
        derive('league', nil, 3, :detector => /\A(leagues?)\Z/)
        derive('cable', nil, Rational(1,10), :detector => /\A(cables?|cbls?)\Z/) do
          derive('fathom', 'fm', Rational(1,10), :detector => /\A(fathoms?|fms?)\Z/) do
            derive('yard', 'yd', Rational(1,6), :detector => /\A(yards?|yds?)\Z/) do
              derive('foot', 'ft', Rational(1,3), :detector => /\A(foot|feet|ft|')\Z/) do
                derive('inch', 'in', Rational(1,12), :detector => /\A(inch|inches|in|")\Z/)
              end
            end
          end
        end
      end
    end
  end
  dimension(:M) do
    system(:SI) do
      base('kilogram', 'kg', :detector => /\A(kilograms?|kg)\Z/) do
        derive('tonne', 't', 1000, :detector => /\A(tonnes?)\Z/) do # metric ton
        end
        derive('gram', 'g', Rational(1, 1000), :detector => /\A(grams?|g)\Z/)
      end
    end
    system(:US) do # Common units for mass and, occasionally, force/weight (http://en.wikipedia.org/wiki/United_States_customary_units#Units_of_mass)
      reference('pound', 'lb', Unit[:M, :SI, 'gram'], 453.59237, :detector => /\A(pounds?|lbs?|#)\Z/) do # avoirdupois
        derive('hundredweight', 'cwt', 100, :detector => /\A(hundredweights?|cwt)\Z/) do
          derive('ton', 't', 20, :detector => /\A(tons?|t)\Z/) do # short ton
          end
        end
        derive('ounce', 'oz', Rational(1, 16), :detector => /\A(ounces?|ozs?)\Z/)
        derive('grain', 'gr', Rational(1, 7000), :detector => /\A(grains?|gr)\Z/) do
          derive('dram', 'dr', 27 + Rational(11, 32), :detector => /\A(drams?|dr)\Z/)
        end
      end
    end
    system(:Imp) do
      reference('pound', 'lb', Unit[:M, :SI, 'gram'], 453.59237, :detector => /\A(pounds?|lbs?|#)\Z/) do
        derive('grain', 'gr', Rational(1, 7000), :detector => /\A(grains?|gr)\Z/)
        derive('drachm', 'dr', Rational(1, 256), :detector => /\A(drachms?|dr)\Z/)
        derive('ounce', 'oz', Rational(1, 16), :detector => /\A(ounces?|ozs?)\Z/)
        derive('stone', nil, 14, :detector => /\A(stones?)\Z/)
        derive('quarter', nil, 28, :detector => /\A(quarters?)\Z/)
        derive('hundredweight', 'cwt', 112, :detector => /\A(hundredweights?|cwt)\Z/)
        derive('ton', 't', 2240, :detector => /\A(tons?|t)\Z/) do # long ton
        end
      end
    end
  end

  dimension(:A) do
    system(:SI) do
      combine('square meter', 'm2', {Unit[:L, :SI, :meter] => 2}, :detector => /\A(sq\.?\s?met(er|re)s?|m2)\Z/) do
        derive('hectare', 'ha', 10000, :format => "%.4f%U") do
        end
      end
    end
    system(:US) do # All measures below are approximations due to the difference between a survey foot and an international foot.
      combine('square yard', 'yd2', {Unit[:L, :US, :yard] => 2}, :detector => /yd2/) do
        derive('acre', nil, 4840)
      end
      combine('square mile', nil, {Unit[:L, :US, :mile] => 2}, :detector => /\A(sq(uare|\.)?\s?miles?)\Z/) do
        self.alias('section', nil, :detector => /\Asections?\Z/) do
          derive('township', 'twp', 36, :detector => /\Atownships?\Z/)
        end
      end
    end
  end

  dimension(:V) do
    system(:SI) do
      combine('cubic meter', 'm3', {Unit[:L, :SI, :meter] => 3}, :detector => /\A(cubic met(er|re)s?|m3)\Z/, :preference => 0.75) do
        derive('cubic decimeter', 'dm3', Rational(1, 1000), :detector => /\A(cubic decimet(er|re)s?|dm3)\Z/, :preference => 0.5) do
          self.alias('liter', 'l', :detector => /\A(lit(er|re)s?|l|L)\Z/) do
            derive('milliliter', 'ml', Rational(1, 1000), :detector => /\A(millilit(er|re)s?|ml|mL)\Z/)
          end
        end
      end
    end
    system(:Imp) do
      reference('ounce', 'fl oz', Unit[:V, :SI, 'milliliter'], 28.4130625, :detector => /\A((fluid )?ounces?|oz)\Z/) do
        derive('gill', 'gi', 5, :detector => /\A(gills?|gis?)\Z/) do
          derive('cup', 'cp', 2, :detector => /\A(cups?|cps?)\Z/) do
            derive('pint', 'pt', 2, :detector => /\A(pints?|pts?)\Z/) do
              derive('quart', 'qt', 2, :detector => /\A(quarts?|qts?)\Z/) do
                derive('gallon', 'gal', 4, :detector => /\A(gallons?|gal)\Z/)
              end
            end
          end
        end
      end
    end
    system(:US) do
      combine('cubic inch', 'in3', {Unit[:L, :US, :inch] => 3}, :detector => /\A(cubic inch(es)?|in3)\Z/ ) do
        derive('gallon', 'g', 231, :detector => /\A(gallons?|gal)\Z/) do
          derive('quart', 'qt', Rational(1,4), :detector => /\A(quarts?|qts?)\Z/) do
            derive('pint', 'pt', Rational(1,2), :detector => /\A(pints?|pts?)\Z/) do
              derive('cup', nil, Rational(1,2), :detector => /\Acups?\Z/) do
                derive('gill', 'gi', Rational(1,2), :detector => /\A(gills?|gis?)\Z/) do
                  derive('fluid ounce', 'fl oz', Rational(1, 4), :detector => /\A((fluid )?ounces?|oz)\Z/) do
                    derive('dram', 'dr', Rational(1, 8), :detector => /\A((fluid )?dra(ch)?ms?|(fl )?drs?)\Z/) do
                      derive('minim', '♏', Rational(1, 60))
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  dimension(:T) do
    system(:SI) do
      base('second', 's', :detector => /\A(seconds?|s)\Z/) do
        derive('minute', 'm', 60, :detector => /\A(minutes?|m)\Z/) do
          derive('hour', 'h', 60, :detector => /\A(hours?|h)\Z/) do
            derive('day', 'd', 24, :detector => /\A(days?)\Z/) do
              derive('week', 'w', 7, :detector => /\A(weeks?|wks?)\Z/)
              derive('year', 'yr', 365 + Rational(1, 4), :detector => /\A(years?|yrs?)\Z/)
            end
          end
        end
      end
    end
  end

  dimension(:Vel) do
    system(:SI) do
      combine('meter per second', 'm/s', {Unit[:L, :SI, :m] => 1, Unit[:T, :SI, :second] => -1}) do
        derive('kilometer per hour', 'km/h', Rational(100, 60*60)) do
        end
      end
    end
    system(:US) do
      combine('mile per hour', 'mph', {Unit[:L, :US, :mile] => 1, Unit[:T, :SI, :hour] => -1}, :detector => /\A(mile per hour|mph)\Z/)
    end
    system(:BA) do
      combine('knot', 'kt', {Unit[:L, :BA, :nm] => 1, Unit[:T, :SI, :hour] => -1}, :detector => /\A(knots?|kts?)\Z/)
    end
  end

  dimension(:F) do
    system(:SI) do
      combine('newton', 'N', {Unit[:M, :SI, :kg] => 1, Unit[:L, :SI, :m] => 1, Unit[:T, :SI, :s] => -2})
    end
    system(:US) do
      # This unit requires an estimate of the force of gravity.
      # Reference: http://en.wikipedia.org/wiki/Pound-force
      combine('pound', 'lbf', {Unit[:M, :US, :lb] => 1, Unit[:L, :US, :ft] => 1, Unit[:T, :SI, :s] => -2}, {:reference_factor => 32.17405, :detector => /\A(lb|lbf|pounds-force)\Z/})
    end
  end

  dimension(:E) do
    system(:SI) do
      combine('joule', 'J', {Unit[:F, :SI, :N] => 1, Unit[:L, :SI, :m] => 1})
    end
    system(:US) do
      combine('foot-pound', 'ft-lbf', {Unit[:F, :US, :lbf] => 1, Unit[:L, :US, :ft] => 1})
    end
  end

  dimension(:P) do
    system(:SI) do
      combine('watt', 'W', {Unit[:E, :SI, :joule] => 1, Unit[:T, :SI, :s] => -1}) do
        derive('kilowatt', 'kW', 1000)
      end
    end
    system(:US) do
      # Using the definition for mechanical horsepower, http://en.wikipedia.org/wiki/Horsepower
#      reference('horsepower', 'hp', Dimensional::Unit[:P, :SI, 'watt'], 745.69987158227022, :detector => /\A(horsepower|hp)\Z/)
      combine('horsepower', 'hp', {Unit[:E, :US, :'ft-lbf'] => 1, Unit[:T, :SI, :m] => -1}, {:reference_factor => 33000})
    end
  end

  dimension(nil) do
    system(:US) do
      base('each', 'ea', :detector => /\Aea(ch)?\Z/) do
        derive('pair', 'pr', 2, :detector => /\A(pr|pair)\Z/)
        derive('dozen', 'dz', 12, :detector => /\A(dz|dozen)\Z/) do
          derive('gross', nil, 12)
        end
        derive('score', nil, 20)
      end
    end
  end
end

class Length < Dimensional::Metric
  self.dimension = Dimensional::Dimension::L
  self.default = Unit[:L, :SI, :m]
end

class EngineDisplacement < Dimensional::Metric
  self.dimension = Dimensional::Dimension::V
  self.default = Unit[:V, :SI, :l]
  self.base = default
  configure(Unit[:V, :US, :in3], {:preference => 2})
end

class MechanicalPower < Dimensional::Metric
  self.dimension = Dimensional::Dimension::P
  self.default = Unit[:P, :SI, :W]
  self.base = default
end