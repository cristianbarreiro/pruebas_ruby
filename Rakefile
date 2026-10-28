# frozen_string_literal: true

require "bundler"
require "rake/testtask"
require "rubocop/rake_task"

# Cada grupo de pruebas puede ejecutarse por separado (rake test:unit, ...).
# `rake test` ejecuta todos los grupos que dependen solo del Gemfile raíz.
TEST_GROUPS = {
  examples: "test/examples/**/*_test.rb",
  unit: "test/unit/**/*_test.rb",
  integration: "test/integration/**/*_test.rb",
  solutions: "test/solutions/**/*_test.rb",
  case_studies: "case_studies/0[1-4]_*/test/**/*_test.rb"
}.freeze

namespace :test do
  TEST_GROUPS.each do |name, pattern|
    Rake::TestTask.new(name) do |task|
      task.description = "Ejecuta las pruebas del grupo #{name}"
      task.libs << "lib" << "test"
      task.pattern = pattern
      task.warning = true
    end
  end

  desc "Ejecuta la suite del caso de estudio REST API (usa su propio Gemfile)"
  task :api do
    Dir.chdir("case_studies/05_rest_api") do
      Bundler.with_unbundled_env do
        sh "bundle install --quiet"
        sh "bundle exec rake test"
      end
    end
  end
end

Rake::TestTask.new(:test) do |task|
  task.description = "Ejecuta ejemplos, unitarias, integración, soluciones y casos 01-04"
  task.libs << "lib" << "test"
  task.test_files = FileList[*TEST_GROUPS.values]
  task.warning = true
end

RuboCop::RakeTask.new(:rubocop)

desc "Ejecuta los benchmarks reproducibles del analizador de logs"
task :benchmark do
  ruby "case_studies/04_log_analyzer/benchmarks/parse_benchmark.rb"
end

task default: %i[test rubocop]
