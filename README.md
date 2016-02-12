# markdown-expander

Adds some new syntax to markdown

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'markdown-expander'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install markdown-expander

## Expressions

```ruby
require "markdown-expander"

MarkdownExpander::Expander.new(
  "# Title: {{thing.title}}"
).render(
  thing: {title: "Hello"}
)
#=> "# Title: Hello"
```

## Loops

```ruby
require "markdown-expander"

template = <<-TEMPLATE
{{thing in stuff}}
# {{thing.title}}
{{end}}
TEMPLATE

MarkdownExpander::Expander.new(template).render(
  stuff: [ {title: "First!"}, {title: "Second!"} ]
)
#=> "# First!\n# Second!\n"
```
