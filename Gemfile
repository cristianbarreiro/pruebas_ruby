# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.4"

# Desde Ruby 3.4 (csv) y 4.0 (logger, benchmark) estas librerías pasaron de
# "default gems" a "bundled gems": siguen instalándose con Ruby, pero bajo
# Bundler solo pueden cargarse si se declaran explícitamente aquí.
gem "benchmark", "~> 0.5"
gem "csv", "~> 3.3"
gem "logger", "~> 1.7"

group :development, :test do
  gem "minitest", "~> 6.0"
  gem "rake", "~> 13.4"
  gem "rubocop", "~> 1.92", require: false
  gem "rubocop-minitest", "~> 0.41", require: false
  gem "rubocop-rake", "~> 0.7", require: false
end
