require 'dimensional/configurator'
require 'rational'
include Dimensional

# Define fundamental dimensions and composite dimensions
# Reference: http://en.wikipedia.org/wiki/Dimensional_Analysis
Dimension.register('Length')
Dimension.register('Mass')
Dimension.register('Time')
Dimension.register('Temperature', 'Temp') # Θ is the proper symbol, but it can't be represented in US ASCII
Dimension.register('Electric Charge', 'Q')
Dimension.register('Area', 'A', {Dimension::L => 2})
Dimension.register('Volume', 'V', {Dimension::L => 3})
Dimension.register('Velocity', 'Vel', {Dimension::L => 1, Dimension::T => -1})

# Define common Systems of Measurement
System.register('SI - International System (kg, tonne, m)', 'SI')
System.register('US Customary (lbs, ton, ft)', 'US')  # http://en.wikipedia.org/wiki/United_States_customary_units
System.register('US Customary Troy (oz)', 'USt')  # http://en.wikipedia.org/wiki/United_States_customary_units
System.register('British Imperial (lbs, ton, ft)', 'Imp')  # http://en.wikipedia.org/wiki/Imperial_units

Configurator.start do
  dimension(:L) do
    system(:SI) do
      base('meter', 'm', :detector => /\A(meters?|m)\Z/) do
        derive('centimeter', 'cm', Rational(1, 100), :detector => /\A(centimeters?|cm)\Z/)
        derive('kilometer', 'km', 1000, :detector => /\A(kilometers?|km)\Z/)
      end
    end
    system(:US) do # As of 1 July 1959 (http://en.wikipedia.org/wiki/United_States_customary_units#Units_of_length)
      reference('yard', 'yd', Unit[:L, :SI, 'meter'], 0.9144, :detector => /\A(yards?|yds?)\Z/) do
        derive('foot', 'ft', Rational(1,3), :detector => /\A(foot|feet|ft|')\Z/, :format => "%p'") do
          prefer(:hull)
          derive('inch', 'in', Rational(1,12), :detector => /\A(inch|inches|in|")\Z/, :format => "%p\"")
        end
        derive('furlong', nil, 220, :detector => /\A(furlongs?)\Z/) do
          derive('mile', 'mi', 8, :detector => /\Amiles?\Z/)
        end
      end
    end
  end
  dimension(:M) do
    system(:SI) do
      base('kilogram', 'kg', :detector => /\A(kilograms?|kg)\Z/) do
        derive('tonne', 't', 1000, :detector => /\A(tonnes?)\Z/) do # metric ton
          prefer(:displacement)
        end
        derive('gram', 'g', Rational(1, 1000), :detector => /\A(grams?|g)\Z/)
      end
    end
    system(:US) do # Common units for mass and, occasionally, force/weight (http://en.wikipedia.org/wiki/United_States_customary_units#Units_of_mass)
      reference('pound', 'lb', Unit[:M, :SI, 'gram'], 453.59237, :detector => /\A(pounds?|lbs?|#)\Z/) do # avoirdupois
        derive('hundredweight', 'cwt', 100, :detector => /\A(hundredweights?|cwt)\Z/) do
          derive('ton', 't', 20, :detector => /\A(tons?|t)\Z/) do # short ton
            prefer(:displacement)
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
          prefer(:displacement)
        end
      end
    end
  end

  dimension(:A) do
    system(:SI) do
      combine('square meter', 'm2', %w(meter meter).map{|name| Unit[:L, :SI, name]}, :detector => /\A(sq\.?\s?meters?|m2)\Z/) do
        derive('hectare', 'ha', 10000, :format => "%.4f%U") do
          prefer(:forestry, :precision => -4, :format => "%s%U")
        end
      end
    end
    system(:US) do # All measures below are approximations due to the difference between a survey foot and an international foot.
      combine('square yard', 'yd2', %w(yard yard).map{|name| Unit[:L, :US, name]}, :detector => /yd2/) do
        derive('acre', nil, 4840)
      end
      combine('square mile', nil, %w(mile mile).map{|name| Unit[:L, :US, name]}, :detector => /\A(sq(uare|\.)?\s?miles?)\Z/) do
        self.alias('section', nil, :detector => /\Asections?\Z/) do
          derive('township', 'twp', 36, :detector => /\Atownships?\Z/)
        end
      end
    end
  end

  dimension(:V) do
    system(:SI) do
      combine('cubic meter', 'm3', %w(meter meter meter).map{|name| Unit[:L, :SI, name]}, :detector => /\A(cubic meters?|m3)\Z/) do
        derive('cubic decimeter', 'dm3', Rational(1, 1000), :detector => /\A(cubic decimeters?|dm3)\Z/) do
          self.alias('liter', 'l', :detector => /\A(liters?|l|L)\Z/) do
            derive('milliliter', 'ml', Rational(1, 1000), :detector => /\A(milliliters?|ml|mL)\Z/)
          end
        end
      end
    end
    system(:Imp) do
      reference('ounce', 'fl oz', Unit[:V, :SI, 'milliliter'], 28.4130625, :detector => /\A((fluid )?ounces?|oz)\Z/)
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

  dimension(:T) do
    system(:SI) do
      base('second', 's', :detector => /\A(seconds?|s)\Z/) do
        derive('minute', 'm', 60, :detector => /\A(minutes?|m)\Z/) do
          derive('hour', 'h', 60, :detector => /\A(hours?|h)\Z/) do
            derive('day', 'd', 24, :detector => /\A(days?)\Z/) do
              prefer(:term, :format => "%.0f%U", :precision => -2)
              derive('week', 'w', 7, :detector => /\A(weeks?|wks?)\Z/)
              derive('year', 'yr', 365 + Rational(1, 4), :detector => /\A(years?|yrs?)\Z/)
            end
          end
        end
      end
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