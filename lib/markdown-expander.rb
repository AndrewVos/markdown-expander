require "version"

module MarkdownExpander
  class Expander
    LOOP_START_MATCH = /{{\s*([a-zA-Z_]*)\s+in\s+([a-zA-Z_.]*)\s*}}/
    LOOP_END_MATCH = /{{\s*end\s*}}/
    EXPRESSION_MATCH = /{{\s*([a-zA-Z_.]+)\s*}}/

    def initialize template
      @template = template
    end

    def render options
      root = Node.new(nil, nil)
      node = root

      @template.each_line do |line|
        if line =~ LOOP_START_MATCH
          new_node = Node.new(node, LoopStart.new($1, $2))
          node.children << new_node
          node = new_node
        elsif line =~ LOOP_END_MATCH
          node = node.parent
        elsif line =~ EXPRESSION_MATCH
          before_match = $`
          after_match = $'
          node.children << Node.new(node, before_match)
          node.children << Node.new(node, Expression.new($1))
          node.children << Node.new(node, after_match)
        else
          node.children << Node.new(node, line)
        end
      end

      evaluate_nodes(root, options)
    end

    def evaluate_nodes root, scope
      lines = []
      root.children.each_with_index do |child, index|
        if child.value.class == Expression
          lines << child.value.evaluate(scope)
        elsif child.value.class == LoopStart
          name = child.value.name.to_sym
          parts = child.value.looper.split(".")
          parts.each do |part|
            scope = scope[part.to_sym]
          end
          scope.each do |item|
            lines << evaluate_nodes(child, {name => item})
          end
        else
          lines << child.value
        end
      end
      lines.join("")
    end

    class Node
      attr_accessor :parent
      attr_accessor :children
      attr_accessor :value
      def initialize parent, value
        @parent = parent
        @value = value
        @children = []
      end
    end

    class LoopStart
      attr_accessor :name, :looper
      def initialize name, looper
        @name = name
        @looper = looper
      end
    end

    class Expression
      def initialize value
        @value = value
      end
      def evaluate scope
        parts = @value.split(".")
        current_scope = scope
        parts.each do |part|
          current_scope = current_scope[part.to_sym]
        end
        current_scope
      end
    end
  end
end
