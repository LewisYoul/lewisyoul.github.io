class Index
  LAYOUT_TEMPLATE = './src/layouts/default.html.erb'.freeze
  INDEX_TEMPLATE = './src/layouts/index.html.erb'.freeze

  def initialize(posts)
    @posts = posts
  end

  def publish
    File.open("./dist/index.html", 'w') do |file|
      page = with_layout { html }
      file.write(page)
    end
  end

  private

  def with_layout
    template = File.read(LAYOUT_TEMPLATE)
    erb = ERB.new(template)
    erb.result(binding)
  end

  def html
    template = File.read(INDEX_TEMPLATE)
    erb = ERB.new(template)
    erb.result(binding)
  end
end