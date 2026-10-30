# frozen_string_literal: true

require "test_helper"
require "stringio"

class CliTest < Minitest::Test
  def setup
    @out = StringIO.new
    @err = StringIO.new
    @executed_paths = []
    @runner = lambda do |path|
      @executed_paths << path
      true
    end
    @cli = RubyLab::CLI.new(out: @out, err: @err, runner: @runner)
  end

  def test_prints_version_and_help
    assert_equal 0, @cli.call(["version"])
    assert_includes @out.string, RubyLab::VERSION

    @out.truncate(0)
    @out.rewind

    assert_equal 0, @cli.call(["help"])
    assert_includes @out.string, "Uso: ruby-lab"
  end

  def test_lists_examples_with_optional_prefix
    code = @cli.call(%w[list 01])

    assert_equal 0, code
    assert_includes @out.string, "01_fundamentos"
    assert_includes @out.string, "01/01"
  end

  def test_runs_example_via_injected_runner
    code = @cli.call(%w[run 01/01])

    assert_equal 0, code
    assert_equal 1, @executed_paths.size
    assert_match(/01_sintaxis_y_convenciones\.rb\z/, @executed_paths.first)
  end

  def test_reports_errors_on_unknown_command_or_missing_example
    assert_equal 1, @cli.call(["desconocido"])
    assert_includes @err.string, "Comando desconocido"

    @err.truncate(0)
    @err.rewind

    assert_equal 1, @cli.call(%w[run 99/99])
    assert_includes @err.string, "No existe el ejemplo"
  end

  def test_handles_missing_run_argument_and_invalid_exercise_level
    assert_equal 1, @cli.call(["run"])
    assert_includes @err.string, "Indica el identificador"

    @err.truncate(0)
    @err.rewind

    assert_equal 1, @cli.call(%w[exercises nivel_invalido])
    assert_includes @err.string, "Nivel desconocido"
  end
end
