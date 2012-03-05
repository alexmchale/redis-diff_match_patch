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
    end

    def teardown
      @autodel.each { |k| @redis.del k } if @autodel
    end

    def test_simple_diff_patch_cycle
      set :doc1, "hello world"
      set :doc2, "Howdy, world!"

      expected_patch = <<-EXPECTED_PATCH.gsub(/^ {8}/, "")
        @@ -1,11 +1,13 @@
        -hello
        +Howdy,
          world
        +!
      EXPECTED_PATCH

      @dmp.diff k(:doc1), k(:doc2), k(:diff)
      assert_equal expected_patch, get(:diff)

      @dmp.patch k(:doc1), k(:diff), k(:result)
      assert_equal "Howdy, world!", get(:result)
    end

    def test_complex_diff_patch_cycle
      set :doc, "hello world"
      set :doc1, "Howdy, world"
      set :doc2, "hello my friends!"

      @dmp.diff k(:doc), k(:doc1), k(:diff1)
      @dmp.diff k(:doc), k(:doc2), k(:diff2)

      @dmp.patch k(:doc), k(:diff1), k(:result)
      @dmp.patch k(:result), k(:diff2), k(:result)

      assert_equal "Howdy, my friends!", get(:result)
    end

    def test_merge_cycle
      set :doc, "hello world"
      set :doc1, "Howdy, world"
      set :doc2, "hello my friends!"

      @dmp.merge k(:doc), k(:doc1), k(:doc2), k(:result)

      assert_equal "Howdy, my friends!", get(:result)
    end

    def test_diff_without_destination_key
      @redis.set k(:doc1), "My name is Alex."
      @redis.set k(:doc2), "Your name is Bob!"

      expected = <<-EXPECTED_PATCH.gsub(/^ {8}/, "")
        @@ -1,6 +1,8 @@
        -My
        +Your
          nam
        @@ -10,9 +10,8 @@
          is 
        -Alex.
        +Bob!
      EXPECTED_PATCH

      actual = @dmp.diff k(:doc1), k(:doc2)

      assert_equal expected, actual
    end

    def test_patch_without_destination_key
      set :doc, "My name is Alex."

      set :diff, <<-PATCH.gsub(/^ {8}/, "")
        @@ -1,6 +1,8 @@
        -My
        +Your
          nam
        @@ -10,9 +10,8 @@
          is
        -Alex.
        +Bob!
      PATCH

      result = @dmp.patch k(:doc), k(:diff)

      assert_equal "Your name is Bob!", result
    end

    def test_merge_without_destination_key
      set :doc, "Page One\nI'd like to tell you a story.\nThen end."
      set :doc1, "Page Two\nI'd like to tell you a wonderful story.\nThen end."
      set :doc2, "Page One\nI'm about to tell you a story.\nThe end, goodbye!"

      expected = "Page Two\nI'm about to tell you a wonderful story.\nThe end, goodbye!"
      actual = @dmp.merge k(:doc), k(:doc1), k(:doc2)

      assert_equal expected, actual
    end

    protected

    def k key
      key = "test-diff-match-patch:#{key}"

      @autodel ||= []
      @autodel.push key
      @autodel.uniq!

      key
    end

    def set key, value
      @redis.set k(key), value

      value
    end

    def get key
      @redis.get k(key)
    end

  end

end
