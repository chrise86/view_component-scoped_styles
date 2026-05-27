# frozen_string_literal: true

module ViewComponent
  module ScopedStyles
    extend ActiveSupport::Concern

    CACHED_VARIABLES = %i[@component_styles @component_id @component_class_map].freeze
    CLASS_SELECTOR_PATTERN = /\.([a-zA-Z_][\w-]*)\b/

    # Default root class for +component_class+ when it matches a selector in the CSS.
    COMPONENT_CSS_CLASS = "component".freeze

    class_methods do
      # Sets which CSS class is the root for +component_class+ (no argument).
      # Also triggers style registration when Rails is loaded (registration also
      # runs via the Railtie for all styled components).
      #
      # All class selectors are rewritten to scoped names in +components.scoped.css+.
      # The primary class uses an id from the full stylesheet (e.g. +.icon+ → +.c-99d08d5a+);
      # other classes get per-class ids (e.g. +.input-box+ → +.c-a1b2c3d4+).
      #
      # Call with a name when the root is not +.component+ (the default).
      #
      # Clears cached generated styles when +name+ changes …
      #
      # @param name [String, nil] selector name without a leading dot (e.g. +"icon"+)
      def component_css_class(name = nil)
        if name
          const_set(:COMPONENT_CSS_CLASS, name)
          clear_component_style_cache
        end
        register_styles_if_rails_loaded
      end

      # Returns processed CSS with scoped class selectors, or +nil+ if none.
      def component_styles
        return @component_styles if defined?(@component_styles)
        return nil unless @styles_block || has_stylesheet?

        generate_component_styles
      end

      # Writes this component's processed styles to the bundled or host stylesheet.
      def register_styles
        return unless @styles_block || has_stylesheet?

        Stylist.register(self)
      end

      # +true+ when a sidecar +.css+ file exists for this component.
      def has_stylesheet?
        stylesheet_path && File.exist?(stylesheet_path)
      end

      def styles(&block)
        @styles_block = block
        register_styles_if_rails_loaded
      end

      private

      def stylesheet_path
        return @stylesheet_path if defined?(@stylesheet_path)

        @stylesheet_path = sidecar_files(["css"]).first
      end

      def register_styles_if_rails_loaded
        return unless defined?(Rails) && Rails.root
        return unless defined?(Rails::Server) # only web server boot path

        register_styles
      end

      def generate_component_styles
        styles_content = generate_styles_content
        css_classes = extract_css_classes(styles_content)
        primary_class = primary_css_class(css_classes)

        @component_id = generate_component_id(styles_content)
        @component_class_map = build_component_class_map(styles_content, css_classes, primary_class)
        @component_styles = replace_css_classes(styles_content, @component_class_map)
      end

      def generate_styles_content
        @styles_block ? @styles_block.call : File.read(stylesheet_path)
      end

      def extract_css_classes(styles_content)
        styles_content.scan(CLASS_SELECTOR_PATTERN).flatten.uniq
      end

      def primary_css_class(css_classes)
        configured = self::COMPONENT_CSS_CLASS.delete_prefix(".")
        css_classes.include?(configured) ? configured : css_classes.first
      end

      def build_component_class_map(styles_content, css_classes, primary_class)
        css_classes.index_with do |css_class|
          if css_class == primary_class
            @component_id
          else
            generate_scoped_class_id(styles_content, css_class)
          end
        end
      end

      def replace_css_classes(styles_content, class_map)
        class_map.keys.sort_by(&:length).reverse.reduce(styles_content) do |content, css_class|
          content.gsub(/\.#{Regexp.escape(css_class)}\b/, ".#{class_map[css_class]}")
        end
      end

      def generate_component_id(styles_content)
        hash = Digest::MD5.hexdigest(styles_content)[0..7]

        "c-#{hash}"
      end

      def generate_scoped_class_id(styles_content, css_class)
        hash = Digest::MD5.hexdigest("#{styles_content}:#{css_class}")[0..7]

        "c-#{hash}"
      end

      def clear_component_style_cache
        CACHED_VARIABLES.each do |ivar|
          remove_instance_variable(ivar) if instance_variable_defined?(ivar)
        end
      end
    end

    # Scoped CSS class for a selector (e.g. +"c-99d08d5a"+).
    #
    # With no argument, returns the scoped root class ({COMPONENT_CSS_CLASS} when it
    # appears in the CSS, otherwise the first class in the stylesheet).
    #
    # @param name [String, Symbol] CSS class without a leading dot (e.g. +"input-box"+)
    def component_class(name = nil)
      return nil unless component_has_styles? || component_has_stylesheet?

      self.class.component_styles

      if name
        class_map = self.class.instance_variable_get(:@component_class_map)
        class_map[name.to_s.delete_prefix(".")]
      else
        self.class.instance_variable_get(:@component_id)
      end
    end

    private

    def component_has_stylesheet?
      self.class.has_stylesheet?
    end

    def component_has_styles?
      self.class.instance_variable_defined?(:@styles_block) &&
        self.class.instance_variable_get(:@styles_block)
    end
  end
end
