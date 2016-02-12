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
end
