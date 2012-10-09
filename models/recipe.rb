class Recipe < ActiveRecord::Base
  has_and_belongs_to_many :categories
  
  serialize :raw_ingredients
  serialize :raw_instructions
  
  attr_accessor :microdata, :page_doc, :site

  # clean this up!!!!
  
  def process
    self.raw_ingredients ||= prop(:ingredients, :array) || selector(:ingredients, :array)
    self.raw_instructions ||= prop(:recipeInstructions, :array) || selector(:instructions, :array)
    self.name ||= prop(:name)
    self.total_time ||= prop(:totalTime, :time)
    self.prep_time ||= prop(:prepTime, :time)
    self.cook_time ||= prop(:cookTime, :time)
    self.servings ||= prop(:recipeYield)
    # @categories ||= prop(:recipeCategory)
  end
  
  def selector(role, format = nil)
    return nil if @site.recipe_selectors.blank? or @site.recipe_selectors[role.to_s].blank?
    results = @page_doc.search( @site.recipe_selectors[role] )
    
    case format
    when :array
      return results.map(&:text)
    end
    
    return results
  end
  
  def prop(name, format = nil)
    property = @microdata.properties[name.to_s]
    return nil if property.nil?
    
    case format
    when :array
      return property.map(&:to_s)
    when :time
      return Recipe.time_converter(property[0].to_s)
    else
      return property[0].to_s
    end
  end
  
  def fetch
    @page_content = open(url) { |f| f.read }
    @page_doc = Nokogiri::HTML(@page_content)
    @page_data = Mida::Document.new(@page_content, url)
    
    @microdata = @page_data.items.select{ |data| data.type == "http://schema.org/Recipe" }[0]
  end
  
  def microdata?
    @microdata.present?
  end
  
  class << self
    
    def time_converter(time)
      return nil if time.nil?
      result = time.match(/T((?<hours>\d+)H)?((?<minutes>\d+)M)?/)
      result[:hours].to_i * 60 + result[:minutes].to_i
    end
    
  end
end