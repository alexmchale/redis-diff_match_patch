# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redis-diff_match_patch"

Gem::Specification.new do |s|
  s.name        = "redis-diff_match_patch"
  s.version     = Redis::DiffMatchPatch::VERSION
  s.authors     = ["Alex McHale"]
  s.email       = ["alex@anticlever.com"]
  s.homepage    = ""
  s.summary     = %q{A Ruby library for computing diff-match-patch on Redis servers.}
  s.description = %q{This library will allow you to perform atomic diffs, patches and merges on Redis strings.}

  s.rubyforge_project = "redis-diff_match_patch"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "redis"
  s.add_development_dependency "turn"
  s.add_development_dependency "rake"
end
