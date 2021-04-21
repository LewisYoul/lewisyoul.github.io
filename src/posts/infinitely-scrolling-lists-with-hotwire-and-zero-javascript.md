---
title: Infinitely Scrolling Lists with Hotwire and Zero JavaScript
summary: Hotwire is the New Magic from the folks over at Basecamp. It allows you to build dynamic modern web applications without needing to write much/any javascript by utilising server rendered HTML. Here we use Hotwire to create an infinitely scrolling list.
date: '18-04-2021'
---

I recently added [hotwire](https://hotwire.dev/) to my pet project [snippetsafe](https://snippetsafe.com) and wanted to see if I could replace the infinite scroll functionalities for the snippet feeds without using any custom javascript at all. I'm happy to say that I succeeded and in this post I'm going to share how.

## What we're going to build

As I built this for snippetsafe I'm going to use the `Snippet` model as an example. For the purposes of this post, a `Snippet` has two attributes - `title`, a string corresponding to the title of the snippet and `body`, text corresponding to the content of the snippet.

The plan is to have an initial route we can hit that will display all of our snippets, from the view rendered by this action we will use the new `turbo_frame_tag` to trigger a request for our snippets (in batches of 8) once the initial page has loaded, much like modern Single Page Apps. The HTML response containing our snippets will automatically be inserted onto our index page by the matching `turbo_frame_tag` present on the page.

At the very bottom of each response will be another `turbo_frame_tag` with a unique identifier that pertains to the next page of snippets that need to be loaded. We'll use the `loading: :lazy` option to ensure that the request for the content of this tag is only triggered once the tag itself is visible on the viewport - i.e. once you have scrolled to the bottom of the page.

## The set up

We're going to need to add the [hotwire-rails](https://github.com/hotwired/hotwire-rails) gem to our rails application before we can get down to business:

```bash
# terminal
bundle add hotwire-rails
bundle install
rails hotwire:install
```

Now we've got everything installed, let's get cracking!

## Create the index action

Firstly we need to create the index route to hit:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :snippets, only: :index
end
```

Then create the controller and add the index action:

```ruby
# app/controllers/snippets_controller.rb
class SnippetsController < ApplicationController
  def index; end
end
```

Finally we add the corresponding view:

```erb
<%# app/views/snippets/index.html.erb %>
<%= turbo_frame_tag "snippets_1", src: shared_snippets_path(page: 1) %>
```

The first two code blocks above are standard rails but it's in the view template where the magic is happening. The `turbo_frame_tag` is being given a unique id of `snippets_1` (which is essentially saying "first page of snippets"), this means that if [Turbo]() receives any matching `<turbo-frame>` in a response from the server it will swap out the content of the tag we have defined on the index page with the content of the tag it receives in the response.

The one final piece in the puzzle is the `src: shared_snippets_path(page: 1)`. We'll define the path shortly, but the important point to note here is that if you provide a `src` attribute to a `<turbo-frame>`, Turbo will automatically make a request to the `src` value when the page is loaded. This means that as soon as our index page is loaded a request is made to `shared_snippets_path(page: 1)` and the response from that endpoint will be inserted into our index page as long as the returned `<turbo-frame>` id matches the one already on the page.

## Define the route that will render our snippets

On snippetsafe the list of snippets is used in many different places. As a result the route to obtain them is under the `shared` namespace. Let's create it!

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :snippets, only: :index

  namespace :shared do
    resources :snippets, only: :index
  end
end
```

Then create the corresponding namespaced controller and action:

```ruby
# app/controllers/shared/snippets_controller.rb
class Shared::SnippetsController < ApplicationController
  PER_PAGE = 8.freeze

  def index
    @page = params[:page] ? params[:page].to_i : 1
    @offset = (@page - 1) * PER_PAGE
    @snippets = Snippet.offset(@offset).limit(PER_PAGE)
    @next_page = @page + 1 if @snippets.size == PER_PAGE
  end
end
```

Finally create the HTML template for this action:

```erb
<%# app/views/shared/snippets.html.erb %>
<%= turbo_frame_tag "snippets_#{@page}" do %>
  <% @snippets.each do |snippet| %>
    <div>
      <h1><%= snippet.title %></h1>
      <p><%= snippet.body %></p>
    </div>
  <% end %>

  <% if @next_page %>
    <%= turbo_frame_tag "snippets_#{@next_page}", loading: :lazy, src: shared_snippets_path(page: @next_page) %>
  <% end %>
<% end %>
```

## What's happening?

As explained above, as soon as we load our index page at `/snippets` Turbo will automatically make a request to this newly created endpoint `shared/snippets?page=1` thanks to the `<turbo-frame>` with the `src` attribute set to `shared_snippets_path(page: 1)`. In the `Shared::SnippetsController#index` action we grab the "page" from the params (or set it if it isn't passed), then we calculate the snippets we want to return through a combination of the ActiveRecord [offset](https://apidock.com/rails/ActiveRecord/QueryMethods/offset) and [limit](https://apidock.com/rails/ActiveRecord/QueryMethods/limit) functions. We finally determine whether there are further snippets to return by checking whether there are fewer snippets returned from the database than the amount we are aiming to show per page (8 - defined by the `PER_PAGE` constant). If there are more snippet to show we set `@per_page` as `@page + 1`. These values are then used in the view.

In the view template, `@page` is interpolated into the `turbo_frame_tag` id so that it matches the id of the `<turbo-frame>` that initiated the request (for the first iteration this is always `"snippets_1"`). Within this `<turbo-frame>` we then render the HTML for each snippet retrieved fromt he database. Finally, still within the same `turbo_frame_tag` and only if there is another page (defined by the `@next_page` variable) we render another `<turbo-frame>` with an id of `"snippets_#{@next_page}"` (which will evaluate to `"snippets_2"` for the first iteration). Again we define the `src` for this frame but passing the `@next_page` as a param. The difference here is that we are also adding `loading: :lazy` which will mean that the request for this `<tubo-frame>` is only made once that frame is visible on the page. Once this happens the cycle starts again but with the page numbers incremented until there are no more snippets to view.

## Job done

You now have the basics of an infinitely scrolling list view but there are still a few things you can do to improve it. How about adding an indicator to your `<turbo-frame>` tags to indicate that you're app is making a request to fetch more snippets? Anything within a `<turbo-frame>` tag is automatically replaced with the corresponding response, so something like this would work nicely:

```erb
<%# app/views/snippets/index.html.erb %>
<%= turbo_frame_tag "snippets_1", src: shared_snippets_path(page: 1) do %>
    <h3>Loading...</h3>
<% end %>
```

I don't want to give you to much guidance in this department as part of the fun of building things is reading the docs and tinkering to see what's possible. Just have fun with it!

## References

* [Hotwire](https://hotwire.dev/)
* [Turbo](https://turbo.hotwire.dev/)
* [Blog post](https://stevepolito.design/blog/rails-infinite-scrolling-blog-roll/) by [@stevepolitodsgn](https://twitter.com/stevepolitodsgn)