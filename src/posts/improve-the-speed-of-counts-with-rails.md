---
title: Counting with ActiveRecord - Count, Size & Length
summary: Choosing the correct method for counting collections in Rails can be confusing. In this post we weigh up the different options ActiveRecord offers us and pick the best tool for the job.
date: '01-05-2021'
---

There are a few options available to you for performing counts of records with ActiveRecord. You would be forgiven for believing that `length`, `size` and `count` are just aliases for one another. In some cases this is true, but there is a clear reason to use one over another in certain situations, this post highlights when to use each option to obtain the best performance from your application.

We'll be referencing a small rails app called "cars", the source code for which can be found [here](https://github.com/LewisYoul/cars) for you to follow along. In this example we are aiming to count the number of cars that are currently parked in each garage in our database. There is a one to many relationship between Garage & Car.

## count

We want to get a [count](https://apidock.com/rails/ActiveRecord/Calculations/ClassMethods/count) of all of the cars in each of our garages and in order to do this we can grab all of our `Garage` records and iterate through them to fetch every `Car` that is parked there. In order to prevent N+1 queries we are using [#includes](https://apidock.com/rails/ActiveRecord/QueryMethods/includes):

```ruby
Garage.includes(:cars).map { |garage| garage.cars.count }
#=> [3, 2, 1, 1, 0]
```

This gives us exactly what we need, however if we look at our SQL logs we can see that every call to `garage.cars.count` is making a request to the database to perform that count:

```
Garage Load (0.4ms)  SELECT "garages".* FROM "garages"
Car Load (0.3ms)  SELECT "cars".* FROM "cars" WHERE "cars"."garage_id" IN ($1, $2, $3, $4, $5)  [[nil, 1], [nil, 2], [nil, 3], [nil, 4], [nil, 5]]
  (0.5ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 1]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 2]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 3]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 4]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 5]]
```

The first line indicates fetching all of our `Garage` records from the database. The second line is `ActiveRecord` eager loading our `Car` records from the database in the hope of preventing N+1 queries. However we can then see five separate requests to the database to fetch the `Car` count for each `Garage`. What the heck, using `#includes` should mean this doesn't happen right?

Well it turns out that `#count` will always make a request to the database to fetch the count of the records we want, regardless of whether we have eager loaded those records or not. This means that we might as well have done the following to save us a request to also fetch all of the cars from the database:

```ruby
Garage.all.map { |garage| garage.cars.count }
```

Which gives us the same result but with one less database hit:

```
Garage Load (0.4ms)  SELECT "garages".* FROM "garages"
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 1]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 2]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 3]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 4]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 5]]
```

So how can we make the most of eager loading to count record associations? Let's have a look at `#length`.

## length

Let's perform the same operation, substituting count for [length](https://apidock.com/ruby/Array/length):

```ruby
Garage.includes(:cars).map { |garage| garage.cars.length }
#=> [3, 2, 1, 1, 0]
```

Much the same on the face of it but if we check the SQL logs we can see that there were no extra requests to the database in order to count the number of cars:

```
Garage Load (0.3ms)  SELECT "garages".* FROM "garages"
Car Load (0.3ms)  SELECT "cars".* FROM "cars" WHERE "cars"."garage_id" IN ($1, $2, $3, $4, $5)  [[nil, 1], [nil, 2], [nil, 3], [nil, 4], [nil, 5]]
```

The reason for this is because `ActiveRecord` is now honouring our eager loading of `Car` records. As it's already performed a query to load all `Car` records associated with each `Garage` it can calculate the number of cars per garage in memory, without needing to hit the database again. It should be noted though, that if you use length when records are not eager loaded it will actually load all of the records you are counting from the database into memory and then count them in Ruby:


```ruby
Garage.all.map { |g| g.cars.length }
```

Produces SQL logs:

```
Garage Load (0.3ms)  SELECT "garages".* FROM "garages"
Car Load (0.2ms)  SELECT "cars".* FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 1]]
Car Load (0.1ms)  SELECT "cars".* FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 2]]
Car Load (0.1ms)  SELECT "cars".* FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 3]]
Car Load (0.1ms)  SELECT "cars".* FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 4]]
Car Load (0.1ms)  SELECT "cars".* FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 5]]
```

## size

Rails has one more trick up its sleeve when it comes to counting records in this way and it's [size](https://apidock.com/rails/ActiveRecord/Associations/AssociationCollection/size). On the face of it size performs the same as length:

```ruby
Garage.includes(:cars).map { |garage| garage.cars.size }
#=> [3, 2, 1, 1, 0]
```

Producing the queries:

```
Garage Load (0.3ms)  SELECT "garages".* FROM "garages"
Car Load (0.3ms)  SELECT "cars".* FROM "cars" WHERE "cars"."garage_id" IN ($1, $2, $3, $4, $5)  [[nil, 1], [nil, 2], [nil, 3], [nil, 4], [nil, 5]]
```

Size has a benefit over length in that it will always perform an SQL `COUNT` statement if the records are not eagerly loaded, rather than loading them all into memory:

```ruby
Garage.all.map { |garage| garage.cars.size }
```

Producing the queries:

```
Garage Load (0.3ms)  SELECT "garages".* FROM "garages"
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 1]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 2]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 3]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 4]]
  (0.2ms)  SELECT COUNT(*) FROM "cars" WHERE "cars"."garage_id" = $1  [["garage_id", 5]]
```

Another perk of this method is that it will also observe a [counter_cache](https://guides.rubyonrails.org/association_basics.html#options-for-belongs-to-counter-cache) if one is present for the association. A big plus!

## Benchmarking

So what does this all mean for performance? Let's compare the options (number in brackets it total execution time):

```ruby
# count
Benchmark.measure { Garage.includes(:cars).map { |g| g.cars.count } }
#=> 0.004082   0.000419   0.004501 (  0.006126)

# length
Benchmark.measure { Garage.includes(:cars).map { |g| g.cars.length } }
#=> 0.001571   0.000140   0.001711 (  0.002080)

# size
Benchmark.measure { Garage.includes(:cars).map { |g| g.cars.size } }
#=> 0.001596   0.000114   0.001710 (  0.002063)
```

As you can see `count` is by far the slowest as it completely ignores the eager loading, while `length` and `size` are pretty much identical because they are both using `length` under the hood.

## Conclusion

So which option should you use? In this scenario you should use either `length` or `size` because we have eager loaded the cars associations. However, in general it's recommended to use `size` as it will automatically delegate to either `count` or `length` depending on whether the association is loaded or not. It will also observe any counter caches that you have on your models.