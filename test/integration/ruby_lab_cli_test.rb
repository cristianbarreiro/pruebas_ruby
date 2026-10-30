# frozen_string_literal: true

require "test_helper"

class RubyLabCliIntegrationTest < Minitest::Test
  BIN_PATH = File.join(TestSupport::ROOT, "bin", "ruby-lab")

  def test_executable_lists_and_runs_example_in_subprocess
    stdout_list, stderr_list, status_list = TestSupport.run_ruby(BIN_PATH, "list", "01")

    assert_predicate status_list, :success?, stderr_list
    assert_includes stdout_list, "01/01"

    stdout_run, stderr_run, status_run = TestSupport.run_ruby(BIN_PATH, "run", "01/01")

    assert_predicate status_run, :success?, stderr_run
    assert_includes stdout_run, "Integer"
  end

  def test_executable_returns_nonzero_exit_code_on_invalid_command
    _stdout, stderr, status = TestSupport.run_ruby(BIN_PATH, "comando-inexistente")

    refute_predicate status, :success?
    assert_includes stderr, "Comando desconocido"
  end
end
