require './markdown_parser.rb'
require 'yaml'
require 'date'

class Post
  attr_reader :basename, :body

  YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze
  LAYOUT_TEMPLATE = './src/layouts/default.html.erb'.freeze
  POST_TEMPLATE = './src/layouts/post.html.erb'.freeze

  def initialize(filepath)
    @filepath = filepath
    @basename = File.basename(@filepath, '.md')
    @content = File.read(@filepath)
    @frontmatter = YAML.load(@content[YAML_FRONT_MATTER_REGEXP])
    @content = @content.sub(YAML_FRONT_MATTER_REGEXP, '')
    @body = MarkdownParser.new.parse(@content)
  end

  def publish
    File.open("./docs/#{@basename}.html", 'w') do |file|
      page = with_layout { html }
      file.write(page)
    end
  end

  def title
    @title ||= @frontmatter['title']
  end

  def summary
    @frontmatter['summary']
  end

  def date
    Date.parse(@frontmatter['date'])
  end

  def path
    "#{@basename}"
  end

  private

  def with_layout
    template = File.read(LAYOUT_TEMPLATE)
    erb = ERB.new(template)
    erb.result(binding)
  end

  def html
    template = File.read(POST_TEMPLATE)
    erb = ERB.new(template)
    erb.result(binding)
  end
end