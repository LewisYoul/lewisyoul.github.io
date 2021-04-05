require 'redcarpet'

class MarkdownParser
  def initialize
    @parser = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  end

  def parse(markdown)
    @parser.render(markdown)
  end
end