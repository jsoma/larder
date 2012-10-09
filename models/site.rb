class Site

  attr_accessor :name, :domain, :search_path, :search_selectors, :uses_microdata, :recipe_selectors, :use
  
  def initialize(options)
    %w(name domain search_path search_selectors uses_microdata recipe_selectors use).each do |attribute|
      send("#{attribute}=", options[attribute])
    end
  end
  
  def search(term, options = {})
    search_url = domain + search_path % term
    content = open(search_url) { |f| f.read }
    doc = Nokogiri::HTML(content)
    
    urls_to_search = doc.search(@search_selectors['result_link']).map{ |r| 
      if r.attribute('href').to_s =~ /^http/
        r.attribute('href').to_s
      else
        domain + r.attribute('href').to_s
      end
    }

    puts urls_to_search.inspect
    
    @recipes ||= []
    
    urls_to_search.each do |url|

      found = Recipe.find_by_url(url)

      if found.present?
        @recipes << found
        next
      end
      

      recipe = Recipe.new(:url => url)

      recipe.fetch

      if recipe.has_microdata?
        recipe.process
        recipe.save
      
        @recipes << recipe
      end
    end

    @recipes
  end
  
  def use?
    @use
  end
  
  class << self
    
    def sites
      @sites ||= YAML::load(File.open("#{Padrino.root}/config/sites.yml"))["sites"].map{ |site_info| Site.new(site_info) }.select(&:use?)
    end
    
    def search(term, options = {})
      sites.map{ |site| site.search(term, options) }.flatten
    end
    
          
  end
  
end