# frozen_string_literal: true

require "strscan"

module ViewComponent
  module ScopedStyles
    # Records each class occurrence with its scope, preserving non-selector CSS.
    class CssSelectors
      COMMENT = %r{/\*.*?\*/}m
      PROTECTED = %r{/\*.*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\\.}m
      CLASS_SELECTOR = /\.([a-zA-Z_][\w-]*)\b/
      ClassSelector = Struct.new(:name, :local)

      attr_reader :local_classes, :global_classes

      def initialize(css)
        @local_classes = []
        @global_classes = []
        @parts = parse_stylesheet(css)
        @local_classes.uniq!
        @global_classes.uniq!
      end

      def render(class_map)
        @parts.map do |part|
          if part.is_a?(ClassSelector)
            name = part.local ? class_map.fetch(part.name) : part.name
            ".#{CssClassPrefix.escape_for_css_selector(name)}"
          else
            part
          end
        end.join
      end

      private

      # A rule's prelude ends at an opening brace. Semicolons and closing
      # braces flush declarations without interpreting them as selectors.
      def parse_stylesheet(css)
        scanner = StringScanner.new(css)
        parts = []
        prelude = +""
        depth = 0

        until scanner.eos?
          if (literal = scanner.scan(PROTECTED))
            prelude << literal
            next
          end

          char = scanner.getch
          case char
          when "(", "["
            depth += 1
          when ")", "]"
            depth -= 1
          end

          if depth.zero? && "{};".include?(char)
            if char == "{"
              parts.concat(parse_prelude(prelude))
            else
              parts << prelude
            end
            parts << char
            prelude = +""
          else
            prelude << char
          end
        end

        parts << prelude
      end

      def parse_prelude(prelude)
        rule = prelude.gsub(COMMENT, "").lstrip
        scanner = StringScanner.new(prelude)
        return parse_selector(scanner) unless rule.start_with?("@") && !rule.match?(/\A@scope\b/)
        return [prelude] unless rule.match?(/\A@supports\b/)

        parts = []
        until scanner.eos?
          if (literal = scanner.scan(PROTECTED))
            parts << literal
          elsif scanner.scan(/\bselector\(/)
            parts << "selector("
            parts.concat(parse_selector(scanner, closing: ")"))
            parts << ")"
          else
            parts << scanner.getch
          end
        end
        parts
      end

      def parse_selector(scanner, local: true, closing: nil, scope_function: false)
        parts = []
        initial_scope = local

        until scanner.eos?
          if closing && scanner.scan(/#{Regexp.escape(closing)}/)
            return parts
          elsif (literal = scanner.scan(PROTECTED))
            parts << literal
          elsif scanner.scan(/\[/)
            parts << "[" << read_attribute(scanner)
          elsif scanner.scan(/:(global|local)\(/)
            scope = scanner[1] == "local"
            parts.concat(parse_selector(scanner, local: scope, closing: ")", scope_function: true))
          elsif scanner.scan(/:(global|local)(?=\s)/)
            local = scanner[1] == "local"
            scanner.scan(/\s+/)
          elsif scanner.scan(CLASS_SELECTOR)
            name = scanner[1]
            (local ? @local_classes : @global_classes) << name
            parts << ClassSelector.new(name, local)
          elsif scanner.scan(/\(/)
            parts << "("
            parts.concat(parse_selector(scanner, local: local, closing: ")"))
            parts << ")"
          elsif scanner.scan(/,/)
            raise ArgumentError, "Use a separate :global(...) or :local(...) for each selector" if scope_function

            local = initial_scope
            parts << ","
          else
            parts << scanner.getch
          end
        end

        raise ArgumentError, "Unclosed selector function in scoped CSS" if closing

        parts
      end

      def read_attribute(scanner)
        value = +""
        until scanner.eos?
          if (literal = scanner.scan(PROTECTED))
            value << literal
          else
            char = scanner.getch
            value << char
            break if char == "]"
          end
        end
        value
      end
    end
  end
end
