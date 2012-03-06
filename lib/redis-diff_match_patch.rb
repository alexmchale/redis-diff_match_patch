require "redis"
require "digest/sha1"

class Redis

  class DiffMatchPatch

    attr_reader :redis

    VERSION      = "1.1.1"

    RESOURCE_DIR = File.dirname(__FILE__)
    DIFF_SCRIPT  = File.read File.join(RESOURCE_DIR, "diff_match_patch-diff.lua")
    DIFF_SHA1    = Digest::SHA1.hexdigest DIFF_SCRIPT
    PATCH_SCRIPT = File.read File.join(RESOURCE_DIR, "diff_match_patch-patch.lua")
    PATCH_SHA1   = Digest::SHA1.hexdigest PATCH_SCRIPT
    MERGE_SCRIPT = File.read File.join(RESOURCE_DIR, "diff_match_patch-merge.lua")
    MERGE_SHA1   = Digest::SHA1.hexdigest MERGE_SCRIPT

    def initialize redis = Redis.new
      @redis = redis
    end

    def diff src_key, dst_key, patch_key = nil
      exec DIFF_SCRIPT, DIFF_SHA1, [ src_key, dst_key, patch_key ]
    end

    def patch src_key, patch_key, dst_key = nil
      exec PATCH_SCRIPT, PATCH_SHA1, [ src_key, patch_key, dst_key ]
    end

    def merge ancestor_key, key1, key2, result_key = nil
      exec MERGE_SCRIPT, MERGE_SHA1, [ ancestor_key, key1, key2, result_key ]
    end

    protected

    def exec script, sha1, args
      @redis.evalsha sha1, args.count, *args
    rescue Exception => e
      if e.message =~ /NOSCRIPT/
        @redis.eval script, args.count, *args
      else
        raise e
      end
    end

  end

end
