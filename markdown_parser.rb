require 'redcarpet'

class MarkdownParser
  def initialize
    @parser = Redcarpet::Markdown.new(Redcarpet::Render::HTML, fenced_code_blocks: true)
  end

  def parse(markdown)
    @parser.render(markdown)
  end
end