Redis: Diff Match Patch
=======================

## DESCRIPTION

Redis: Diff Match Patch is a library for using [Google's diff-match-patch][1]
on a Redis server.

This library uses the Lua port included with diff-match-patch to atomically
calculate and apply patches of string values stored in Redis.

## PREREQUISITES

This library requires a Redis server with Lua scripting support (EVAL and
EVALSHA commands). This support was added in Redis 2.6.

## INSTALLATION

### To install manually from RubyGems:

    gem install redis-diff_match_patch

### To use in a project with Bundler, edit your Gemfile to have:

    gem 'redis-diff_match_patch'

## API

    dmp = Redis::DiffMatchPatch.new(REDIS_CLIENT)

    # Calculate a diff of two keys
    dmp.diff ORIGINAL_KEY, CURRENT_KEY, DIFF_OUTPUT_KEY

    # Patch a key
    dmp.patch ORIGINAL_KEY, DIFF_KEY, RESULT_OUTPUT_KEY

    # Perform a 3-way merge
    dmp.merge ANCESTOR_KEY, KEY1, KEY2, RESULT_OUTPUT_KEY

#### The output keys are optional. All API methods will return the result value.

## EXAMPLES

### Calculate the diff of an original document and a current version of that document.

		redis = Redis.new
		dmp = Redis::DiffMatchPatch.new redis

		redis["original"] = "hello world"
		redis["doc"] = "Hello, world!"

		dmp.diff "original", "doc", "diff"

		redis["diff"] #=> "@@ -1,11 +1,13 @@\n-h\n+H\n ello\n+,\n  world\n+!\n"

### Perform a 3-way merge on two documents that are variations from an original source.

    redis = Redis.new
    dmp = Redis::DiffMatchPatch.new redis

    redis["original"] = "hello world"
    redis["doc1"] = "Howdy, world!"
    redis["doc2"] = "hello my friends"

    dmp.merge "original", "doc1", "doc2", "result"

    redis["result"] #=> "Howdy, my friends!"

[1]: http://code.google.com/p/google-diff-match-patch/
