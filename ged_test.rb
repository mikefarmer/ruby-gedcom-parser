#!/usr/bin/env ruby
require 'ged_parse'

# Get the file
ged_filename = "test_parse.ged"
#ARGV[0]

puts ged_filename

g = GedParse::Gedcom.new(ged_filename)
puts g.tags.join(',')

puts "\n\nFamilies:"
puts "------------------------------------"
g.families.each do |family|
  if family.husband
    puts "HUSBAND: #{family.husband.name}"
    family.husband.details.each do |detail|
      puts "-- #{detail[:field]}: #{detail[:value]}"
    end
  end
  
  if family.wife
    puts "WIFE: #{family.wife.name}"
    family.wife.details.each do |detail|
      puts "-- #{detail[:field]}: #{detail[:value]}"
    end
  end
  
  puts "CHILDREN:"
  family.children.each do |child|
    puts "-- #{child.name}"
    child.details.each do |detail|
      puts "---- #{detail[:field]}: #{detail[:value]}"
    end
  end
    
    
end

puts "\n\nOther Sections(#{g.sections.length}):"
puts "------------------------------------"
g.sections.each do |section|
  puts "SECTION: #{section.gid}"
  section.details.each do |detail|
    puts "-- #{detail[:field]}: #{detail[:value]}"
  end
end