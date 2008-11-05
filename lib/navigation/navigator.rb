module RPH
  module Navigation
    # Navigation class is used to extract some of the cruft out of the helper itself
    # 
    # If you need to extend the functionality, add methods to the Navigation class as
    # the navigation helper generates a new instance of this class
    class Navigator	
      include Error

      def initialize(sections, options)
        @sections = sections
        @options = options
        validate_sections!
        fill_subtitles if has_subtitles?
      end
	
      # will return the links passed in, removing subtitles if they exist
      def sections
        has_subtitles? ? parse(@sections) : @sections
      end
	
      # default behavior if subtitles are present without the <tt>:hover_text => true</tt> option
      def wants_subtitles?
        has_subtitles? && !wants_hover_text? && !wants_link_text?
      end
	
      # determines if the subtitles are to be shown as link titles onhover
      def wants_hover_text?
        has_subtitles? && @options.has_key?(:hover_text) && @options[:hover_text]
      end

      #determines if the subtitles should also be the link text
      def wants_link_text?
        has_subtitles? && @options.has_key?(:link_text) && @options[:link_text]
      end
	
      # turns <tt>:contact_me</tt> into 'Contact Me'
      def text_for(link)
        link.to_s.humanize.split.inject([]) do |words, word|
          words << word.capitalize
        end.join(' ')
      end
	
      # returns the method used for checking if links are allowed to
      # be added to the list (defaults to <tt>logged_in?</tt> method)
      def authorization_method
        method = :logged_in?
        if @options.has_key?(:authorize)
          method = @options[:with] if @options.has_key?(:with)
        end
        method
      end
	
      # returns an array of the methods that require authorization
      # (returns all methods if <tt>[:all]</tt> is passed in)
      def methods_to_authorize
        methods = []
        if requires_authorization?
          methods = @options.values_at(:authorize).flatten
        end
        authorize_all?(methods) ? sections : methods
      end
  
      # returns the additional CSS class to be set on all authorized links
      def authorized_css
        return '' if methods_to_authorize.blank?
        @options[:authorized_css] ||= 'authorized_nav_link'
      end
  
      protected
      # distinguishes between sections and subtitles, returning sections
      def parse(sections)
        temp = []
        sections.each_with_index do |section, index|
          temp << section if section.is_a?(Symbol) && index.even?
        end
        temp
      end
  
      # ensures that the links passed in are valid
      def validate_sections!
        raise(InvalidSections, InvalidSections.message) unless sections_is_an_array?
        if has_subtitles?
          raise(InvalidArrayCount, InvalidArrayCount.message) unless one_to_one_match_for_sections_and_subtitles?
        end
        raise(InvalidType, InvalidType.message) unless valid_types?
      end
    
      private      
      # loads the SUBTITLES constant with key/value relationships for section/subtitle
      def fill_subtitles
        @sections.in_groups_of(2) { |group| SUBTITLES[group[0]] = group[1] }
      end
	
      # assumed that if all items are symbols, subtitles are not present
      def has_subtitles?
        !@sections.all? { |section| section.is_a?(Symbol) }
      end
			
      def requires_authorization?
        @options.has_key?(:authorize) && !@options[:authorize].blank?
      end
	
      def authorize_all?(methods)
        return false if methods.blank?
        methods.size == 1 && methods[0] == :all
      end
  
      def sections_is_an_array?
        @sections.is_a?(Array)
      end
  
      def one_to_one_match_for_sections_and_subtitles?
        @sections.size % 2 == 0
      end

      def valid_types?
        !(@sections.first.is_a?(String) || @sections.all? { |section| section.is_a?(String) })
      end
    end
  end
end