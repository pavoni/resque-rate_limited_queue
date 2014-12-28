# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resque-rate_limited_queue/version'

Gem::Specification.new do |spec|
  spec.name          = "resque-rate_limited_queue"
  spec.version       = RateLimitedQueue::VERSION
  spec.authors       = ["Greg Dowling"]
  spec.email         = ["mail@greddowling.com"]
  spec.summary     = %q{A Resque plugin to help manage jobs that use rate limited apis, pausing when you hit the limits and restarting later.}
  spec.description = %q{A Resque plugin which allows you to create dedicated queues for jobs that use rate limited apis.
These queues will pause when one of the jobs hits a rate limit, and unpause after a suitable time period.
The rate_limited_queue can be used directly, and just requires catching the rate limit exception and pausing the
queue. There are also additional queues provided that already include the pause/rety logic for twitter, angelist
and evernote; these allow you to support rate limited apis with minimal changes.}

  spec.homepage      = "http://github.com/pavoni/resque-rate-limited-queue"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency('resque', '~> 1.9', '>= 1.9.10')
  spec.add_dependency('redis-mutex','~> 4.0', '>= 4.0.0')

  spec.add_dependency("angellist_api", '~> 1.0', '>= 1.0.7')
  spec.add_dependency("evernote-thrift", '~> 1.25', '>= 1.25.1')
  spec.add_dependency("twitter", '~> 5.11', '>= 5.11.0')


  spec.add_development_dependency("bundler", "~> 1.7")
  spec.add_development_dependency("rake", "~> 10.0")
  spec.add_development_dependency("rspec", "~> 2.6")
  spec.add_development_dependency("simplecov", '~> 0.9.1')


end
