# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ruby_lab"

# Utilidades compartidas por las pruebas del proyecto principal.
module TestSupport
  ROOT = File.expand_path("..", __dir__)

  module_function

  # Carga una solución de ejercicio. Por defecto usa solutions/, pero la variable
  # RUBY_LAB_SOLUTIONS_DIR permite ejecutar la misma suite contra el código del
  # alumno, por ejemplo: RUBY_LAB_SOLUTIONS_DIR=mi_trabajo bundle exec rake test:solutions
  def require_solution(relative_path)
    base = File.expand_path(ENV.fetch("RUBY_LAB_SOLUTIONS_DIR", "solutions"), ROOT)
    require File.join(base, "#{relative_path}.rb")
  end

  def example_path(relative_path)
    File.join(ROOT, "examples", relative_path)
  end

  # Ejecuta un script Ruby en un proceso hijo y devuelve [stdout, stderr, status].
  def run_ruby(*args, stdin: "", chdir: ROOT, env: {})
    Open3.capture3(env, RbConfig.ruby, *args, stdin_data: stdin, chdir: chdir)
  end
end
