require "version"

module MarkdownExpander
  class Expander
    LOOP_START_MATCH = /{{\s*([a-zA-Z_]*)\s+in\s+([a-zA-Z_.]*)\s*}}/
    END_MATCH = /{{\s*end\s*}}/
    EXPRESSION_MATCH = /{{\s*([a-zA-Z_.]+)\s*}}/
    IF_START_MATCH = /{{\s*if\s*([a-zA-Z_.]*)\s*(==|!=)\s*"(.*)"}}/

    def initialize template
      @template = template
    end

    def render scope
      root = Node.new(nil, nil)
      node = root

      @template.each_line do |line|
        if line =~ LOOP_START_MATCH
          new_node = Node.new(node, LoopStart.new($1, $2))
          node.children << new_node
          node = new_node
        elsif line =~ IF_START_MATCH
          new_node = Node.new(node, IfStart.new($1, $2, $3))
          node.children << new_node
          node = new_node
        elsif line =~ END_MATCH
          node = node.parent
        else
          loop do
            if line =~ EXPRESSION_MATCH
              before_match = $`
              after_match = $'
              node.children << Node.new(node, before_match)
              node.children << Node.new(node, Expression.new($1))
              line = after_match
            else
              node.children << Node.new(node, line)
              break
            end
          end
        end
      end

      evaluate_nodes(root, scope)
    end

    def drill_down_to_value scope, expression
      expression_parts = expression.split(".").map(&:to_sym)
      expression_parts.each do |part|
        scope = scope[part]
      end
      scope
    end

    def evaluate_nodes root, scope
      lines = []
      root.children.each_with_index do |child, index|
        if child.element.class == Expression
          lines << drill_down_to_value(scope, child.element.expression)
        elsif child.element.class == LoopStart
          name = child.element.name.to_sym
          scope = drill_down_to_value(scope, child.element.expression)
          scope.each do |item|
            lines << evaluate_nodes(child, {name => item})
          end
        elsif child.element.class == IfStart
          value = drill_down_to_value(scope, child.element.expression)
          expression_satisfied =
            (child.element.operator == "==" && value.to_s == child.element.value) ||
            (child.element.operator == "!=" && value.to_s != child.element.value)
          if expression_satisfied
            lines << evaluate_nodes(child, scope)
          end
        else
          lines << child.element
        end
      end
      lines.join("")
    end

    class Node
      attr_accessor :parent
      attr_accessor :children
      attr_accessor :element
      def initialize parent, element
        @parent = parent
        @element = element
        @children = []
      end
    end

    class LoopStart
      attr_accessor :name, :expression
      def initialize name, expression
        @name = name
        @expression = expression
      end
    end

    class IfStart
      attr_accessor :expression
      attr_accessor :operator
      attr_accessor :value
      def initialize expression, operator, value
        @expression = expression
        @operator = operator
        @value = value
      end
    end

    class Expression
      attr_accessor :expression
      def initialize expression
        @expression = expression
      end
    end
  end
end
