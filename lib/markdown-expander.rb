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

    def render options
      root = Node.new(nil, nil)
      node = root

      @template.each_line do |line|
        if line =~ LOOP_START_MATCH
          new_node = Node.new(node, LoopStart.new($1, $2))
          node.children << new_node
          node = new_node
        elsif line =~ END_MATCH
          node = node.parent
        elsif line =~ IF_START_MATCH
          new_node = Node.new(node, IfStart.new($1, $2, $3))
          node.children << new_node
          node = new_node
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

      evaluate_nodes(root, options)
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
        if child.value.class == Expression
          lines << drill_down_to_value(scope, child.value.expression)
        elsif child.value.class == LoopStart
          name = child.value.name.to_sym
          scope = drill_down_to_value(scope, child.value.looper)
          scope.each do |item|
            lines << evaluate_nodes(child, {name => item})
          end
        elsif child.value.class == IfStart
          value = drill_down_to_value(scope, child.value.expression)
          expression_satisfied =
            (child.value.operator == "==" && value.to_s == child.value.value) ||
            (child.value.operator == "!=" && value.to_s != child.value.value)
          if expression_satisfied
            scope.each do |item|
              lines << evaluate_nodes(child, scope)
            end
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
