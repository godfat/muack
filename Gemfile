
source 'https://rubygems.org'

gemspec

gem 'rake'
gem 'pork'

gem 'simplecov', :require => false if ENV['COV']
gem 'coveralls', :require => false if ENV['CI']

platform :rbx do
  gem 'rubysl-singleton' # used in rake
end
