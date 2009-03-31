module Menus
	class Base < Tags::Node
	  attr_accessor :id, :url, :branch, :options, :active
	  
		def initialize(id, options = {})
		  @id = id
		  [:text, :tag, :url, :branch].each { |key| instance_variable_set(:"@#{key}", options.delete(key)) }
		  super(options)
	  end
		
    def definitions
      @definitions ||= []
    end
    
    def item(id, options = {}, &block)
      type = options.delete(:type) || Menus::Base
      item = insert_at_position(type.new(id, options), *options.values_at(:before, :after))
      item.definitions << block if block
    end
    
    def text
      @text ||= id.is_a?(Symbol) ? I18n.t(id, :scope => :'adva.titles') : id
    end
	  
	  def content
	    @content ||= url ? Tags::A.new(text, :href => url) : Tags::Span.new(text)
    end
    
    def empty?
      children.empty?
    end
    
		def render(scope, options = {})
		  build(scope) if options.delete(:build)
		  activate(options.delete(:activate)) if options.key?(:activate)
		  html = !empty? && matches?(options.slice(:level)) ? render_menu(scope, options) : render_children(scope, options)
		  if parent.try(:matches?, options.slice(:level)) || parent.nil? && empty?
		    html = Tags::Li.new(content.render + html, :class => (active == true ? 'active' : nil)).render
	    end
		  html
	  end
	  
	  def matches?(options)
	    values = []
	    values << (level == options[:level] - 1) if options.key?(:level)
	    values << (branch == options[:branch])   if options.key?(:branch) # && branch
	    values.inject(true) { |result, value| result && value }
    end
    
    def activate(path)
      if path
        path == url ? self_and_parents.each { |item| item.active = true } : self.active = false
        children.each { |child| child.activate(path) }
      end
    end
    
    protected
    
      def build(scope)
        @children = Tags::TagsList.new(self)
        @active = nil

        klass = (class << scope; self; end)
        scope.instance_variable_set(:@_menu_, self)
        klass.send(:define_method, :method_missing) { |m, *args, &block| @_menu_.respond_to?(m) ? @_menu_.send(m, *args, &block) : super }

        definitions.each { |definition| scope.instance_eval(&definition) }
        klass.send(:remove_method, :method_missing)

        children.each { |child| child.send(:build, scope) if child.respond_to?(:build) }
      end
	  
  	  def render_menu(scope, options)
  		  [true, nil].include?(active) ? Tags::Ul.new(options.slice(:id, :class)).render do |html|
  		    children.each { |child| html << child.render(scope, options) if child.matches?(options.slice(:branch)) }
  	    end : ''
      end
    
      def render_children(scope, options)
        children.map { |child| child.render(scope, options) }.join
      end
	end
end