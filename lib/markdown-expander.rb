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
      root = Node.new(nil, nil, 1)
      node = root
      current_line = 1

      @template.each_line do |line|
        if line =~ LOOP_START_MATCH
          new_node = Node.new(node, LoopStart.new($1, $2), current_line)
          node.children << new_node
          node = new_node
        elsif line =~ IF_START_MATCH
          new_node = Node.new(node, IfStart.new($1, $2, $3), current_line)
          node.children << new_node
          node = new_node
        elsif line =~ END_MATCH
          node = node.parent
        else
          loop do
            if line =~ EXPRESSION_MATCH
              before_match = $`
              after_match = $'
              node.children << Node.new(node, before_match, current_line)
              node.children << Node.new(node, Expression.new($1), current_line)
              line = after_match
            else
              node.children << Node.new(node, line, current_line)
              break
            end
          end
        end
        current_line += 1
      end

      errors = []
      if node != root
        if node.element.class == IfStart
          errors << "LINE #{node.line_number}: if statement has no end"
        elsif node.element.class == LoopStart
          errors << "LINE #{node.line_number}: loop has no end"
        end
      end

      if errors.any?
        RenderResult.new(nil, errors)
      else
        begin
          RenderResult.new(evaluate_nodes(root, scope), [])
        rescue ExpressionDrillDownError => e
          RenderResult.new(nil, ["LINE #{e.node.line_number}: expression '#{e.expression}' could not be evaluated"])
        end
      end
    end

    class ExpressionDrillDownError < StandardError
      attr_reader :node
      attr_reader :expression
      def initialize node, expression
        @node = node
        @expression = expression
      end
    end

    def drill_down_to_value node, scope, expression
      expression_parts = expression.split(".").map(&:to_sym)
      expression_parts.each do |part|
        begin
          scope = scope[part]
        rescue NoMethodError
          raise ExpressionDrillDownError.new(node, expression)
        end
      end
      scope
    end

    def evaluate_nodes root, scope
      lines = []
      root.children.each_with_index do |child, index|
        if child.element.class == Expression
          lines << drill_down_to_value(child, scope, child.element.expression)
        elsif child.element.class == LoopStart
          name = child.element.name.to_sym
          scope = drill_down_to_value(child, scope, child.element.expression)
          scope.each do |item|
            lines << evaluate_nodes(child, {name => item})
          end
        elsif child.element.class == IfStart
          value = drill_down_to_value(child, scope, child.element.expression)
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

    class RenderResult
      attr_reader :body
      attr_reader :errors
      def initialize body, errors
        @body = body
        @errors = errors
      end
    end

    class Node
      attr_accessor :parent
      attr_accessor :children
      attr_accessor :element
      attr_accessor :line_number
      def initialize parent, element, line_number
        @parent = parent
        @element = element
        @line_number = line_number
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
