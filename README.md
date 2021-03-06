# markdown-expander

A preprocessor for markdown that adds simple logic.

## Why would you do this?????

This was written to be used on anmo.io, where users can create web pages with
markdown, but also need to have some simple templating language.

Because users are going to be inputting content, I can't use any templating
language that allows them to execute ruby code.

Liquid seemed far too complex and heavyweight for what I want and also didn't
work well when mixed with markdown.

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

## Logic

```ruby
require "markdown-expander"

template = <<-TEMPLATE
{{animal in animals}}
  {{if animal.name == "cats"}}
# {{animal.name}} are the best!!!!!
  {{end}}
{{end}}
TEMPLATE

MarkdownExpander::Expander.new(template).render(
  animals: [ {name: "dogs"}, {name: "cats"} ]
)
#=> "# cats are the best!!!!!\n"
```
