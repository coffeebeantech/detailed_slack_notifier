# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'detailed_slack_notifier/version'

Gem::Specification.new do |spec|
  spec.name          = 'detailed_slack_notifier'
  spec.version       = DetailedSlackNotifier::VERSION
  spec.authors       = ['Ramon Carvalho Maciel']
  spec.email         = ['ramongtx@gmail.com']

  spec.summary       = 'A plugin for exception_notification that sends slack notifications with detailed data'
  spec.description   = 'A plugin for exception_notification that sends slack notifications with detailed data'
  spec.homepage      = 'http://github.com/coffeebeantech/detailed_slack_notifier'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_dependency 'rails', '>= 3.0.4'
  spec.add_dependency 'slack-notifier', '~> 1.5'
end
