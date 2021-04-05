---
title: Searching Rails Logs with Grep
summary: Rails logs can contain a lot of output so finding what you're looking for can be troublesome at times. Here are a few tricks for quickly finding what you need, from printing out a single line to multiple lines and their surrounding context.
date: '04-04-2021'
---

## Just grep

Return all occurrences of a string (I will be using 'appsignal' as an example) from the log.

```bash
grep appsignal log/production.log
```

## Return the first n matches

Very similar to the first command but pass the  `-m` (max count) option to limit the number of results returned.

```bash
grep -m 5 appsignal log/production.log
```

## Return n lines before/after the match

Returning a single line from a log without any of the logs that occured before or after it isn't particularly useful. Thankfully you can pass the `-A` or `-B` options with a number as an argument to also print the lines above or below the matching string. Passing `-A 10` will print the matching line as well as the 10 lines preceeding it.

```bash
grep -A 10 appsignal log/production.log
```

While passing `-B 10` will print the matching line as well as the 10 lines after it.

```bash
grep -B 10 appsignal log/production.log
```

A shortcut to returning the lines both above and below is to use the `-C` (context) option which will return both the preceeding and subsequent lines following a match.

```bash
grep -C 10 appsignal log/production.log
```

## Search from the bottom of the file

You may have noticed that the `man` command defaults to searching from the top of the file, this is not ideal if you want to print out the occurrences of a match that were logged most recently to your file. A quick and easy way to find the most recent matches is essentially to reverse the file and then search through the result. The `cat` command will dump the contents of your file to STDOUT and the `tac` command will do exactly the same but from the bottom! We can then pipe this output to `grep` and search it as we would in the previous examples.

To find the most recent log of your match (appsignal) and display the 5 lines above and below it you can use the following command.

```bash
tac log/production.log | grep -m 1 -C 5 appsignal
```

There are most certainly other ways to do this but I have found this solution to be simple and reliable. I hope it can be useful to you too. Please do drop me a message on [twitter](https://twitter.com/lewisyoul) if you have any different or better mechanisms for searching logs!