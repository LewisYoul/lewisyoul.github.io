---
title: Automate your RSpec test suite with Guard
summary: Rails logs can contain a lot of output so finding what you're looking for can be troublesome at times. Here are a few tricks for quickly finding what you need, from printing out a single line to multiple lines and their surrounding context.
date: '09-04-2021'
---

[RSpec](https://rspec.info/) is a wonderful tool for testing regular ruby and ruby on rails applications. However as an application and its test suite grows larger it can become cumbersome to run an entire suite or even an enire file when you make a change. Even switching between your editor and terminal to execute `bundle exec rspec` can become tiresome if you are regularly running your specs or practicing [Test Driven Development](https://en.wikipedia.org/wiki/Test-driven_development). Wouldn't it be wonderful if a tool existed that could automate the process of running your tests and only run them for files or tests that have actually changed?! Thankfully such a tool exists and it's called [guard](https://github.com/guard/guard). The official docs summarise it better than I can.

> Guard automates various tasks by running custom rules whenever file or directories are modified. It's frequently used by software developers, web designers, writers and other specialists to avoid mundane, repetitive actions and commands such as "relaunching" tools after changing source files or configurations.

## Installation

Thankfully [guard-rspec](https://github.com/guard/guard-rspec) has been developed to allow us to integrate rspec with guard seamlessly and there are only a few steps required to get up and running on an existing rails app.

Firstly add guard-rspec to the development group in your Gemfile:

```ruby
group :development do
  gem 'guard'
end
```

Install it by running bundler:

```bash
bundle install
```

Generate a `Guardfile` with default rspec configurations:

```bash
bundle exec guard init rspec
```

This command will generate a file that will look something like this:

```ruby
# Guardfile
guard :rspec, cmd: "bundle exec rspec" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)

  # Rails files
  rails = dsl.rails(view_extensions: %w(erb haml slim))
  dsl.watch_spec_files_for(rails.app_files)
  dsl.watch_spec_files_for(rails.views)

  watch(rails.controllers) do |m|
    [
      rspec.spec.call("routing/#{m[1]}_routing"),
      rspec.spec.call("controllers/#{m[1]}_controller"),
      rspec.spec.call("acceptance/#{m[1]}")
    ]
  end

  # Rails config changes
  watch(rails.spec_helper)     { rspec.spec_dir }
  watch(rails.routes)          { "#{rspec.spec_dir}/routing" }
  watch(rails.app_controller)  { "#{rspec.spec_dir}/controllers" }

  # Capybara features specs
  watch(rails.view_dirs)     { |m| rspec.spec.call("features/#{m[1]}") }
  watch(rails.layouts)       { |m| rspec.spec.call("features/#{m[1]}") }

  # Turnip features and steps
  watch(%r{^spec/acceptance/(.+)\.feature$})
  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$}) do |m|
    Dir[File.join("**/#{m[1]}.feature")][0] || "spec/acceptance"
  end
end
```

## Running Guard

Now that we've got guard configured we need to actually use it. Previously if we wanted to run a test with rspec we would need to pass the file as an argument directly and every time we either changed the spec or the target file (in this case `models/books.rb`) we would have to execute this command.

```bash
bundle exec rspec spec/models/books_spec.rb
```

Guard removes this hassle such that all we now need to do is start the guard process running with:

```bash
bundle exec guard
```

In your terminal you should now see confirmation that guard is running and listening for changes to your application:

```bash
16:19:58 - INFO - Guard::RSpec is running
```

Now if you make a change to `models/books.rb` guard will automatically run the tests in `spec/models/books_spec.rb` meaning you never need to re-enter your terminal and directly execute the `rspec` command again!

Guard is highly customisable allowing you to specify which files to watch and which specs to trigger on a change to those files and even create custom watcher classes. For a full overview of how to customise guard and get the most out of its many features cheack out the [official documentation](https://github.com/guard/guard).