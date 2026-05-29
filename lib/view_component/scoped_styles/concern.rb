# frozen_string_literal: true

require "digest"

module ViewComponent
  module ScopedStyles
    extend ActiveSupport::Concern

    CACHED_VARIABLES = %i[@component_styles @component_id @component_class_map].freeze
    CLASS_SELECTOR_PATTERN = /\.([a-zA-Z_][\w-]*)\b/

    # Default root class for +component_class+ when it matches a selector in the CSS.
    COMPONENT_CSS_CLASS = "component".freeze
    IGNORED_CSS_CLASSES = [].freeze

    class_methods do
      # Sets which CSS class is the root for +component_class+ (no argument).
      # Also triggers style registration in development when Rails is loaded
      # (registration also runs via the Railtie for all styled components).
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
          const_set(:COMPONENT_CSS_CLASS, name.to_s)
          clear_component_style_cache
        end
        register_styles_if_rails_loaded
      end

      # Declares CSS class selectors that are not rewritten to scoped names.
      #
      # Ignored classes stay in +components.scoped.css+ as written (e.g. +.is-open+).
      # +component_class("is-open")+ returns the original name.
      #
      # Clears cached generated styles when the list changes.
      #
      # @param classes [String, Symbol] selector names without a leading dot
      def ignored_css_classes(*classes)
        if classes.any?
          names = classes.flatten.map { |css_class| css_class.to_s.delete_prefix(".") }
          const_set(:IGNORED_CSS_CLASSES, names.freeze)
          clear_component_style_cache
        end
        register_styles_if_rails_loaded
      end

      # Sets the prefix for scoped class names on this component (e.g. +"vc-"+ → +"vc-a1b2c3d4"+).
      #
      # Overrides {ViewComponent::ScopedStyles.configuration}.css_class_prefix for this component.
      #
      # Clears cached generated styles when +prefix+ changes.
      #
      # @param prefix [String, nil] prefix without a hash suffix (e.g. +"c-"+, +"vc-"+)
      def css_class_prefix(prefix = nil)
        if prefix
          const_set(:CSS_CLASS_PREFIX, prefix.to_s)
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

      # Writes this component's processed styles to +components.scoped.css+.
      # Only runs in development; production and test use the committed stylesheet.
      def register_styles
        return unless register_styles_to_stylesheet?
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
        return unless register_styles_to_stylesheet?
        return unless defined?(Rails::Server) # only web server boot path

        register_styles
      end

      def register_styles_to_stylesheet?
        defined?(Rails::Application) && Rails.application && Rails.env.development?
      end

      def generate_component_styles
        styles_content = generate_styles_content
        css_classes = extract_css_classes(styles_content)
        primary_class = primary_css_class(css_classes)

        @component_id = component_id_for(primary_class, styles_content)
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
          if ignored_css_class?(css_class)
            css_class
          else
            generate_scoped_class_id(styles_content, css_class, primary_class)
          end
        end
      end

      def replace_css_classes(styles_content, class_map)
        scoped_map = class_map.reject do |css_class, scoped|
          css_class == scoped
        end

        sorted_classes = scoped_map.keys.sort_by(&:length).reverse

        sorted_classes.reduce(styles_content) do |content, css_class|
          content.gsub(/\.#{Regexp.escape(css_class)}\b/, ".#{class_map[css_class]}")
        end
      end

      def component_id_for(primary_class, styles_content)
        if ignored_css_class?(primary_class)
          primary_class
        else
          generate_scoped_class_id(styles_content, primary_class, primary_class)
        end
      end

      def ignored_css_class?(css_class)
        self::IGNORED_CSS_CLASSES.include?(css_class)
      end

      def generate_scoped_class_id(styles_content, css_class, primary_class)
        is_primary = css_class == primary_class
        input = is_primary ? styles_content : "#{styles_content}:#{css_class}"
        hash = ::Digest::MD5.hexdigest(input)[0..7]

        "#{scoped_css_class_prefix}#{hash}"
      end

      def scoped_css_class_prefix
        if const_defined?(:CSS_CLASS_PREFIX, false)
          self::CSS_CLASS_PREFIX
        else
          ViewComponent::ScopedStyles.configuration.css_class_prefix
        end
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
