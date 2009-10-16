require 'dimensional/configurator'
require 'rational'

# Define fundamental dimensions and composite dimensions
# Reference: http://en.wikipedia.org/wiki/Dimensional_Analysis
Dimensional::Dimension.register('Length')
Dimensional::Dimension.register('Mass')
Dimensional::Dimension.register('Time')
Dimensional::Dimension.register('Temperature', 'Temp') # Θ is the proper symbol, but it can't be represented in US ASCII
Dimensional::Dimension.register('Electric Charge', 'Q')
Dimensional::Dimension.register('Area', 'A', {Dimensional::Dimension[:L] => 2})
Dimensional::Dimension.register('Volume', 'V', {Dimensional::Dimension[:L] => 3})

# Define common Systems of Measurement
Dimensional::System.register('SI - International System (kg, tonne, m)', 'SI')
Dimensional::System.register('US Customary (lbs, ton, ft)', 'US')  # http://en.wikipedia.org/wiki/United_States_customary_units
Dimensional::System.register('US Customary Troy (oz)', 'USt')  # http://en.wikipedia.org/wiki/United_States_customary_units
Dimensional::System.register('British Imperial (lbs, ton, ft)', 'Imp')  # http://en.wikipedia.org/wiki/Imperial_units

Dimensional::Configurator.start do
  dimension(:L) do
    system(:SI) do
      base('meter', :detector => /\A(meters?|m)\Z/, :abbreviation => 'm') do
        derive('centimeter', 1e-2, :detector => /\A(centimeters?|cm)\Z/, :abbreviation => 'cm')
        derive('kilometer', 1e3, :detector => /\A(kilometers?|km)\Z/, :abbreviation => 'km')
      end
    end
    system(:US) do # As of 1 July 1959 (http://en.wikipedia.org/wiki/United_States_customary_units#Units_of_length)
      reference('yard', Dimensional::Unit[:L, :SI, 'meter'], 0.9144, :detector => /\A(yards?|yds?)\Z/, :abbreviation => 'yd') do
        derive('foot', Rational(1,3), :detector => /\A(foot|feet|ft|')\Z/, :abbreviation => "ft", :format => "%p'") do
          prefer(:hull)
          derive('inch', Rational(1,12), :detector => /\A(inch|inches|in|")\Z/, :abbreviation =>"in", :format => "%p\"")          
        end
        derive('furlong', 220, :detector => /\A(furlongs?)\Z/) do
          derive('mile', 8, :detector => /\Amiles?\Z/, :abbreviation => 'mi')
        end
      end
    end
  end
  dimension(:M) do
    system(:SI) do
      base('kilogram', :detector => /\A(kilograms?|kg)\Z/, :abbreviation => 'kg') do
        derive('tonne', 1e3, :detector => /\A(tonnes?)\Z/, :abbreviation => 't') do # metric ton
          prefer(:displacement)
        end
        derive('gram', 1e-3, :detector => /\A(grams?|g)\Z/, :abbreviation => 'g')
      end
    end
    system(:US) do # Common units for mass and, occasionally, force/weight (http://en.wikipedia.org/wiki/United_States_customary_units#Units_of_mass)
      reference('pound', Dimensional::Unit[:M, :SI, 'gram'], 453.59237, :detector => /\A(pounds?|lbs?|#)\Z/, :abbreviation => 'lb') do # avoirdupois
        derive('hundredweight', 100, :detector => /\A(hundredweights?|cwt)\Z/, :abbreviation => 'cwt') do
          derive('ton', 20, :detector => /\A(tons?|t)\Z/, :abbreviation => 't') do # short ton
            prefer(:displacement)
          end
        end
        derive('grain', 7000**-1, :detector => /\A(grains?|gr)\Z/, :abbreviation => 'gr') do
          derive('dram', 27 + Rational(11, 32), :detector => /\A(drams?|dr)\Z/, :abbreviation => 'dr') do
            derive('ounce', :detector => /\A(ounces?|ozs?)\Z/, :conversion => [437.5, :grain], :abbreviation => 'oz') 
          end
        end
      end
    end
    system(:Imp) do
      reference('pound', Dimensional::Unit[:M, :SI, 'gram'], 453.59237, :detector => /\A(pounds?|lbs?|#)\Z/, :abbreviation => 'lb') do
        derive('grain', 7000**-1, :detector => /\A(grains?|gr)\Z/, :abbreviation => 'gr')
        derive('drachm', 256**-1, :detector => /\A(drachms?|dr)\Z/, :abbreviation => 'dr')
        derive('ounce', 16**-1, :detector => /\A(ounces?|ozs?)\Z/, :abbreviation => 'oz')
        derive('stone', 14, :detector => /\A(stones?)\Z/)
        derive('quarter', 28, :detector => /\A(quarters?)\Z/)
        derive('hundredweight', 112, :detector => /\A(hundredweights?|cwt)\Z/, :abbreviation => 'cwt')
        derive('ton', 2240, :detector => /\A(tons?|t)\Z/, :abbreviation => 't') do # long ton
          prefer(:displacement)
        end
      end
    end
  end
  dimension(:A) do
    system(:SI) do
      combine('square meter', %w(meter meter).map{|name| Dimensional::Unit[:L, :SI, name]}, :detector => /\A(sq\.?\s?meters?|m2)\Z/, :abbreviation => 'm2') do
        derive('hectare', 10000, :format => "%.4f%U", :abbreviation => 'ha') do
          prefer(:forestry, :precision => -4, :format => "%s%U")
        end
      end
    end
    system(:US) do # All measures below are approximations due to the difference between a survey foot and an international foot.
      combine('square yard', %w(yard yard).map{|name| Dimensional::Unit[:L, :US, name]}, :detector => /yd2/, :abbreviation => 'yd2') do
        derive('acre', 4840.0)
      end
      combine('square mile', %w(mile mile).map{|name| Dimensional::Unit[:L, :US, name]}, :detector => /\A(sq(uare|\.)?\s?miles?)\Z/) do
        self.alias('section', :detector => /\Asections?\Z/) do
          derive('township', 36, :detector => /\Atownships?\Z/)
        end
      end
    end
  end

  dimension(:V) do
    system(:SI) do
      combine('cubic meter', %w(meter meter meter).map{|name| Dimensional::Unit[:L, :SI, name]}, :detector => /\A(cubic meters?|m3)\Z/, :abbreviation => "m3") do
        derive('cubic decimeter', 1e-3, :detector => /\A(cubic decimeters?|dm3)\Z/, :abbreviation => "dm3") do
          self.alias('liter', :detector => /\A(liters?|l|L)\Z/, :abbreviation => "l") do
            derive('milliliter', 1E-3, :detector => /\A(milliliters?|ml|mL)\Z/, :abbreviation => "ml")
          end
        end
      end
    end
    system(:Imp) do
      reference('ounce', Dimensional::Unit[:V, :SI, 'milliliter'], 28.4130625, :detector => /\A((fluid )?ounces?|oz)\Z/, :abbreviation => "fl oz")
      #  register :ounce, :conversion => [28.4130625, :milliliter], :detector => /\A(imperial\s(fluid )?imp\.\sounces?|imp\.\soz)\Z/, :abbreviation => "imp. oz"
      #  register :gill, :conversion => [5, :ounce], :detector => /\A(gills?|gi)\Z/, :abbreviation => "gi"
      #  register :cup, :conversion => [2, :gill], :detector => /\A(cups?)\Z/, :abbreviation => "cp"
      #  register :pint, :conversion => [2, :cup], :detector => /\A(pints?|pt)\Z/, :abbreviation => "pt"
      #  register :quart, :conversion => [2, :pint], :detector => /\A(quarts?|qt)\Z/, :abbreviation => "qt"
      #  register :gallon, :conversion => [4, :quart], :detector => /\A(gallons?|gal)\Z/, :abbreviation => "gal"
    end
    system(:US) do
      #  # Common US Customary units for volume, based on the SI Base Unit 'liter'
      #  register :minim, :conversion => [0.00006161152, :liter], :abbreviation => "min"  # Base Unit
      #  register :dram, :conversion => [60, :minim], :abbreviation => "fl dr"
      #  register :ounce, :conversion => [8, :dram], :detector => /\A((fluid )?ounces?|oz)\Z/, :abbreviation => "fl oz"
      #  register :gill, :conversion => [4, :ounce], :detector => /\A(gills?|gi)\Z/, :abbreviation => "gi"
      #  register :cup, :conversion => [2, :gill], :detector => /\A(cups?)\Z/, :abbreviation => "cp"
      #  register :pint, :conversion => [2, :cup], :detector => /\A(pints?|pt)\Z/, :abbreviation => "pt"
      #  register :quart, :conversion => [2, :pint], :detector => /\A(quarts?|qt)\Z/, :abbreviation => "qt"
      #  register :gallon, :conversion => [4, :quart], :detector => /\A(gallons?|gal)\Z/, :abbreviation => "gal"
    end
  end
    
  dimension(nil) do
    system(:US) do
      base('each', :detector => /\Aea(ch)?\Z/, :abbreviation => 'ea') do
        derive('pair', 2, :detector => /\A(pr|pair)\Z/, :abbreviation => 'pr')
        derive('dozen', 12, :detector => /\A(dz|dozen)\Z/, :abbreviation => 'dz') do
          derive('gross', 12)
        end
        derive('score', 20)
      end
    end
  end
end    
