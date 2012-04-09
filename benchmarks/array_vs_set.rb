require 'rubygems'
require 'tach'
require 'set'

# Compare speed of simple addition and iteration operations.
#
Tach.meter(1000) do
  
  tach('array') do
    a = []
    (1..1000).each do |i|
      a << i
    end
    a.each do |i|
      "this is a string with #{i}"
    end
  end
  
  tach('set') do
    s = Set.new
    (1...1000).each do |i|
      s << i
    end
    s.each do |i|
      "this is a string with #{i}"
    end
  end
  
end