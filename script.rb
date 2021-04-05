
#!/usr/bin/env ruby

require 'erb'
require 'byebug'
require './index.rb'
require './post.rb'

posts_filepaths = Dir['./src/posts/*.md']
posts = posts_filepaths.map { |filepath| Post.new(filepath) }

Index.new(posts).publish
posts.each(&:publish)


# basename = File.basename(filepath, '.md')

# File.open("./dist/#{basename}.html", 'w') do |file|
#   content = File.read(filepath)
#   frontmatter = content[YAML_FRONT_MATTER_REGEXP]
#   config = YAML.load(frontmatter)
#   body = content.sub(YAML_FRONT_MATTER_REGEXP, '')

#   byebug

#   html = MarkdownParser.new.parse(content)
#   file.write(html)
#   puts "Wrote the following:\n-------------------\n\n", html
# end