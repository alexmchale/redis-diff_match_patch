require "turn"
require "minitest/autorun"
require "turn/autorun"

Turn.config do |c|
  c.format  = :pretty
  c.trace   = nil
  c.natural = true
  c.ansi    = true
end

class Redis

  class TestDiffMatchPatch < MiniTest::Unit::TestCase

    def setup
      @redis = Redis.new
      @dmp = DiffMatchPatch.new @redis

      @k = {}

      %w( doc doc1 doc2 diff diff1 diff2 result ).each do |k|
        @k[k] = "test-diff-match-patch:#{k}"
        @redis.del @k[k]
      end
    end

    def teardown
      @k.each { |k, v| @redis.del v }
    end

    def test_simple_diff_patch_cycle
      doc1_key = "test-diff-match-patch:doc1"
      doc2_key = "test-diff-match-patch:doc2"
      diff_key = "test-diff-match-patch:diff"
      result_key = "test-diff-match-patch:result"

      @redis[doc1_key] = "hello world"
      @redis[doc2_key] = "Howdy, world!"
      @redis.del diff_key
      @redis.del result_key

      expected_patch = <<-EXPECTED_PATCH.gsub(/^ {8}/, "")
        @@ -1,11 +1,13 @@
        -hello
        +Howdy,
          world
        +!
      EXPECTED_PATCH

      @dmp.diff doc1_key, doc2_key, diff_key
      assert_equal expected_patch, @redis[diff_key]

      @dmp.patch doc1_key, diff_key, result_key
      assert_equal "Howdy, world!", @redis[result_key]
    end

    def test_complex_diff_patch_cycle
      doc1_key = "test-diff-match-patch:doc1"
      doc2_key = "test-diff-match-patch:doc2"
      doc3_key = "test-diff-match-patch:doc3"
      diff1_key = "test-diff-match-patch:diff1"
      diff2_key = "test-diff-match-patch:diff2"
      result_key = "test-diff-match-patch:result"

      @redis[doc1_key] = "hello world"
      @redis[doc2_key] = "Howdy, world"
      @redis[doc3_key] = "hello my friends!"
      @redis.del diff1_key
      @redis.del diff2_key
      @redis.del result_key

      @dmp.diff doc1_key, doc2_key, diff1_key
      @dmp.diff doc1_key, doc3_key, diff2_key

      @dmp.patch doc1_key, diff1_key, result_key
      @dmp.patch result_key, diff2_key, result_key

      assert_equal "Howdy, my friends!", @redis[result_key]
    end

    def test_merge_cycle
      doc1_key = "test-diff-match-patch:doc1"
      doc2_key = "test-diff-match-patch:doc2"
      doc3_key = "test-diff-match-patch:doc3"
      result_key = "test-diff-match-patch:result"

      @redis[doc1_key] = "hello world"
      @redis[doc2_key] = "Howdy, world"
      @redis[doc3_key] = "hello my friends!"
      @redis.del result_key

      @dmp.merge doc1_key, doc2_key, doc3_key, result_key

      assert_equal "Howdy, my friends!", @redis[result_key]
    end

    def test_diff_without_destination_key
      @redis[@k["doc1"]] = "My name is Alex."
      @redis[@k["doc2"]] = "Your name is Bob!"

      expected_diff = <<-EXPECTED_PATCH.gsub(/^ {8}/, "")
        @@ -1,6 +1,8 @@
        -My
        +Your
          nam
        @@ -10,9 +10,8 @@
          is 
        -Alex.
        +Bob!
      EXPECTED_PATCH

      actual_diff = @dmp.diff @k["doc1"], @k["doc2"]

      assert_equal expected_diff, actual_diff
    end

    def test_patch_without_destination_key
      @redis[@k["doc"]] = "My name is Alex."
      @redis[@k["diff"]] = <<-PATCH.gsub(/^ {8}/, "")
        @@ -1,6 +1,8 @@
        -My
        +Your
          nam
        @@ -10,9 +10,8 @@
          is 
        -Alex.
        +Bob!
      PATCH

      result = @dmp.patch @k["doc"], @k["diff"]

      assert_equal "Your name is Bob!", result
    end

    def test_merge_without_destination_key
      @redis[@k["doc"]] = "Page One\nI'd like to tell you a story.\nThen end."
      @redis[@k["doc1"]] = "Page Two\nI'd like to tell you a wonderful story.\nThen end."
      @redis[@k["doc2"]] = "Page One\nI'm about to tell you a story.\nThe end, goodbye!"

      expected = "Page Two\nI'm about to tell you a wonderful story.\nThe end, goodbye!"
      actual = @dmp.merge @k["doc"], @k["doc1"], @k["doc2"]

      assert_equal expected, actual
    end

  end

end
