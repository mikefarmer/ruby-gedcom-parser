#
#  Created by Michael Farmer on 2007-07-20.

module GedParse

  class GedDetailList
    attr_reader :list

    def initialize 
      @list = []
    end

    def add_detail(level, tag, val)

      case level.to_i
      when 0 
        raise "Level cannot be Zero"
      when 1
        h = {}
        h[:field] = tag
        h[:level] = level
        h[:value] = val
        h[:root] = tag
        @list.push h
      else
        last_detail = @list.last
        last_tag = last_detail[:field]
        last_level = last_detail[:level]
        last_val = last_detail[:value]
        last_root = last_detail[:root]
        if tag == 'CONT'
          last_detail[:value] = [last_val.to_s + "\n" + val.to_s]
        elsif tag == 'CONC'
          last_detail[:value] = [last_val.to_s + val.to_s] 
        else
          if level > last_level
            h = {}
            h[:root] = last_tag 
            h[:field] = last_tag + '_' + tag.to_s 
            h[:level] = level
            h[:value] = val          
            @list.push h
          else
            h = {}
            h[:root] = last_root
            h[:field] = last_root + '_' + tag
            h[:level] = level
            h[:value] = val
            @list.push h
          end
        end
      end
      return @list.last
    end

  end

  class GedSection
    attr_reader :details, :gid

    def initialize(gid)
      @gid = gid
      @d_list = GedDetailList.new
      @details = []
    end

    def add_detail(level, tag, val)
      @d_list.add_detail level, tag, val
      @details = @d_list.list
      return @details.last
    end

    def fields
      f = []
      @d_list.each do |detail|
        f.push detail[:field]
      end
      return f.uniq
    end

    def is_general?
      return true
    end

    def is_individual?
      return false
    end

    def is_family?
      return false
    end
  end

  class Individual < GedSection
    attr_reader  :name

    def initialize(gid)
      @name = ''
      super
    end

    def add_detail(level,tag, val)
      @name = val if tag == 'NAME'
      super
    end

    def is_general?
      return false
    end

    def is_individual?
      return true
    end

  end

  class Family < GedSection
    attr_reader :children, :husband, :wife

    def initialize(gid)
      @children = []
      @husband = nil
      @wife = nil
      super
    end

    def add_relation(type, individual)
      raise "No Individual to add" if ! individual
      @husband = individual if type == 'HUSB'
      @wife = individual if type == 'WIFE'
      @children.push individual if type == 'CHIL'
      return individual
    end

    def is_general?
      return false
    end

    def is_family?
      return true
    end

  end

  class Gedcom
    attr_reader :individuals, :families, :tags, :sections

    def initialize(file_name)
      @file_name = file_name
      refresh
    end

    def refresh 
      @individuals = []
      @families = []
      @tags = []
      @sections = []

      f = File.new(@file_name, 'r')
      # initial pass, get meta data about the gedcom
      f.each do |gedline|
        level, tag, rest = gedline.chop.split(' ', 3)
        @tags.push tag
        @tags.uniq!
      end
      f.rewind

      # second pass, get individuals
      section_type = ''
      section = nil
      f.each do |gedline|

        level, tag, rest = gedline.chop.split(' ', 3)

        if level.to_i == 0
          # push the last section
          case section_type 
          when 'INDI'
            @individuals.push section if section
          when 'FAM'
            @families.push section if section
          else 
            @sections.push section if section
          end

          #start a new section
          case rest.to_s.chomp
          when 'INDI'
            #create an individual
            section = Individual.new(tag)
            section_type = 'INDI'
          when 'FAM'
            #create a family
            section = Family.new(tag)
            section_type = 'FAM'
          else 
            #create a general section
            section = GedSection.new(tag)
            section_type = ''
          end
        else
          #add a detail to the section
          if section_type == 'FAM' && ['HUSB', 'WIFE', 'CHIL'].include?(tag)
            section.add_relation(tag, find_by_individual_gid(rest)) if section
          else
            section.add_detail level, tag, rest if section
          end
        end
      end 
      # add the last section
      case section_type 
      when 'INDI'
        @individuals.push section if section
      when 'FAM'
        @families.push section if section
      else 
        @sections.push section if section
      end
      @individuals.compact!
      @families.compact!
      @sections.compact!        
      f.close   
      return true
    end

    def find_by_family_gid
      retval = nil
      @families.each do |f|
        if f.gid == gid
          retval = f
          break
        end
      end

      return retval
    end

    def find_by_individual_gid(gid)
      retval = nil
      @individuals.each do |i|
        if i.gid == gid 
          retval = i
          break
        end
      end
      raise "Individual not found #{gid}" if ! retval 
      return retval
    end

  end

  
  
end

