require 'html_diff'

# Let's have a :tag option for finders
ActiveRecord::Base.class_eval do
  class << self
    VALID_FIND_OPTIONS << :tags
  end
end

WillPaginate::Finder::ClassMethods.class_eval do
  alias :wp_count_without_tags :wp_count unless method_defined? :wp_count_without_tags
  def wp_count(options, *args)
    wp_count_without_tags(options.except(:tags), *args)
  end
end

class Content < ActiveRecord::Base
  # TODO is this needed?
  class Version < ActiveRecord::Base
    filters_attributes :none => true
  end
    
  translates :title, :body, :excerpt, :body_html, :excerpt_html, 
    :versioned  => [ :title, :body, :excerpt, :body_html, :excerpt_html ], 
    :if_changed => [ :title, :body, :excerpt ], :limit => 5
  acts_as_taggable

  instantiates_with_sti
  has_permalink :title, :url_attribute => :permalink, :sync_url => true, :only_when_blank => true, :scope => :section_id
  filtered_column :body, :excerpt

  belongs_to :site
  belongs_to :section
  belongs_to_author :validate => false # FIXME add validations to Article and Wikipage

  has_many :assets, :through => :asset_assignments
  has_many :asset_assignments # TODO :dependent => :delete_all?
  has_many :activities, :as => :object # move to adva_activity?
  has_many :categories, :through => :categorizations
  has_many :categorizations, :as => :categorizable, :dependent => :destroy, :include => :category

  before_validation :set_site
  
  default_scope :order => 'position, published_at'

  named_scope :published, lambda { { 
    :conditions => ['contents.published_at <= ? AND contents.published_at IS NOT NULL', Time.zone.now],
    :order => :published_at 
  } }
  
  class << self
    def find_every(options)
      if tags = options.delete(:tags)
        options = find_options_for_find_tagged_with(tags, options.update(:match_all => true))
      end
      super options
    end
    
    def find_published_in_time_delta(*args, &block)
      with_published { find_in_time_delta *args, &block }
    end

    def find_in_time_delta(*args)
      options = args.extract_options!
      with_time_delta *args do find(:all, options) end
    end

    def with_published(&block)
      conditions = ['contents.published_at <= ? AND contents.published_at IS NOT NULL', Time.zone.now]
      with_scope({:find => {:conditions => conditions}}, &block)
    end

    def with_time_delta(*args, &block)
      return yield if args.compact.empty?
      conditions = ["contents.published_at BETWEEN ? AND ?", *Time.delta(*args)]
      with_scope({:find => {:conditions => conditions}}, &block)
    end

    def method_missing(name, *args, &block)
      if name.to_s =~ /find_(all_)?published/
        with_published { send name.to_s.sub('_published', ''), *args, &block }
      else
        super
      end
    end
  end

  def owner
    section
  end

  # Using callbacks for such lowlevel things is just awkward. So let's hook in here.
  def attributes=(attributes, guard_protected_attributes = true)
    attributes.symbolize_keys!
    category_ids = attributes.delete(:category_ids)
    returning super do update_categories category_ids if category_ids end
  end

  def diff_against_version(version)
    # return '(orginal version)' if version == versions.earliest.version
    version = versions[version]
    HtmlDiff.diff version.excerpt_html + version.body_html, excerpt_html + body_html
  end

  protected

    def set_site
      self.site_id = section.site_id if section
    end

    def update_categories(category_ids)
      categories.each do |category|
        category_ids.delete(category.id.to_s) || categories.delete(category)
      end
      unless category_ids.blank?
        categories << Category.find(:all, :conditions => ['id in (?)', category_ids])
      end
    end
end