require 'test_helper'

class MarkdownExpander::ExpanderTest < Minitest::Test
  def scope
    {
      page: {title: "My Page"},
      pages: [{title: "Title 1"}, {title: "Title 2"}],
      pages_by_year: [
        {
          year: "2012",
          pages: [
            {title: "Title 1"},
            {title: "Title 2"},
          ],
        },
        {
          year: "2016",
          pages: [
            {title: "Title 3"},
            {title: "Title 4"},
          ],
        }
      ],
    }
  end

  def test_renders_expressions
    example = <<-EXAMPLE
# A header

## {{ page.title }}
    EXAMPLE

    expected_result = <<-RESULT
# A header

## My Page
    RESULT

    result = MarkdownExpander::Expander.new(example).render(scope)
    assert_equal expected_result, result
  end

  def test_renders_loops
    example = <<-EXAMPLE
# A header

{{ page in pages }}
## {{ page.title }}
{{ end }}
    EXAMPLE

    expected_result = <<-RESULT
# A header

## Title 1
## Title 2
    RESULT

    result = MarkdownExpander::Expander.new(example).render(scope)
    assert_equal expected_result, result
  end

  def test_handles_multiple_expressions_per_line
    example = "[{{ page.title }}]({{ page.path }})"
    scope = {page: {title: "title", path: "/some/path"}}
    result = MarkdownExpander::Expander.new(example).render(scope)
    assert_equal "[title](/some/path)", result
  end

  def test_renders_multiple_levels_of_loops
    example = <<-EXAMPLE
# A header

{{ by_year in pages_by_year }}
## {{ by_year.year }}

  {{ page in by_year.pages }}
## {{ page.title }}
  {{ end }}

{{ end }}
    EXAMPLE

    expected_result = <<-RESULT
# A header

## 2012

## Title 1
## Title 2

## 2016

## Title 3
## Title 4

    RESULT

    result = MarkdownExpander::Expander.new(example).render(scope)
    assert_equal expected_result, result
  end

  def test_evaluates_positive_condition
    example = <<-EXAMPLE
# Header
{{if page.title == "My Page"}}
## {{page.title}}
{{end}}
    EXAMPLE

    expected_result = <<-RESULT
# Header
## My Page
    RESULT

    result = MarkdownExpander::Expander.new(example).render(scope)
    assert_equal expected_result, result
  end

  def test_evaluates_negative_condition
    example = <<-EXAMPLE
# Header
{{if page.title != "Something else"}}
## {{page.title}}
{{end}}
    EXAMPLE

    expected_result = <<-RESULT
# Header
## My Page
    RESULT

    result = MarkdownExpander::Expander.new(example).render(scope)
    assert_equal expected_result, result
  end

  def test_if_statements_must_end
    example = "TITLE:\n{{if x == \"1\"}}"
    error = render_error example
    assert_equal(2, error.line_number)
    assert_equal("if statement has no end", error.message)
  end

  def test_loops_must_end
    example = "TITLE\n\n#heading\n{{page in pages}}"
    error = render_error example
    assert_equal(4, error.line_number)
    assert_equal("loop has no end", error.message)
  end

  def test_values_must_be_evaluatable
    example = "\n\n\n\n{{something.that.doesnt.work}}"
    error = render_error example
    assert_equal(5, error.line_number)
    assert_equal("expression 'something.that.doesnt.work' could not be evaluated", error.message)
  end

  def render_error content
    begin
      MarkdownExpander::Expander.new(content).render(scope)
      nil
    rescue MarkdownExpander::Expander::MarkdownExpandError => e
      e
    end
  end

  def render content, scope
    MarkdownExpander::Expander.new(content).render(scope)
  end
end
