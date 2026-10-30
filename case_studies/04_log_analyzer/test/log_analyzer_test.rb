# frozen_string_literal: true

require "test_helper"
require "csv"
require "json"
require "stringio"
require "tmpdir"
require_relative "../lib/log_analyzer"

class LogAnalyzerTest < Minitest::Test
  SAMPLE_LOG = File.expand_path("../data/sample_app.log", __dir__)

  def test_parser_parses_valid_log_line
    line = "2026-03-10 08:03:12 [ERROR] order-worker - Timeout conectando a base de datos primaria"
    entry = LogAnalyzer::Parser.parse_line(line)

    refute_nil entry
    assert_equal "2026-03-10 08:03:12", entry.timestamp
    assert_equal "2026-03-10", entry.date
    assert_equal "ERROR", entry.level
    assert_equal "order-worker", entry.service
    assert_predicate entry, :error?
  end

  def test_parser_returns_nil_for_malformed_lines
    assert_nil LogAnalyzer::Parser.parse_line(nil)
    assert_nil LogAnalyzer::Parser.parse_line("")
    assert_nil LogAnalyzer::Parser.parse_line("LINEA_CORRUPTA_SIN_FORMATO")
    assert_nil LogAnalyzer::Parser.parse_line("2026-03-10 08:00:00 [TRACE] svc - Nivel inválido")
    assert_nil LogAnalyzer::Parser.parse_line("2026-13-45 99:00:00 [INFO] svc - Fecha inválida")
  end

  def test_analyzer_counts_levels_and_malformed_lines_on_sample_log
    report = LogAnalyzer::Analyzer.new(SAMPLE_LOG).analyze

    assert_equal 13, report.total_lines
    assert_equal 11, report.valid_entries
    assert_equal 2, report.malformed_lines
    assert_equal 11, report.matched_entries
    assert_equal 5, report.counts_by_level["ERROR"]
    assert_equal 3, report.counts_by_level["INFO"]
  end

  def test_analyzer_detects_repeated_error_patterns
    report = LogAnalyzer::Analyzer.new(SAMPLE_LOG).analyze

    expected_errors = {
      "Timeout conectando a base de datos primaria" => 3,
      "Token JWT expirado o firma inválida" => 2
    }

    assert_equal expected_errors, report.repeated_errors
  end

  def test_analyzer_filters_by_level_service_date_and_query
    analyzer = LogAnalyzer::Analyzer.new(
      SAMPLE_LOG,
      level: "ERROR",
      service: "order-worker",
      from_date: "2026-03-10",
      to_date: "2026-03-10",
      query: "timeout"
    )
    report = analyzer.analyze

    assert_equal 2, report.matched_entries
    assert_equal({ "ERROR" => 2 }, report.counts_by_level)
    assert_equal({ "order-worker" => 2 }, report.counts_by_service)
  end

  def test_stream_entries_returns_lazy_enumerator
    analyzer = LogAnalyzer::Analyzer.new(SAMPLE_LOG, level: "ERROR")
    stream = analyzer.stream_entries

    assert_instance_of Enumerator::Lazy, stream
    first_two = stream.first(2)

    assert_equal 2, first_two.size
    assert(first_two.all?(&:error?))
  end

  def test_reporter_writes_json_in_tmpdir
    report = LogAnalyzer::Analyzer.new(SAMPLE_LOG).analyze

    Dir.mktmpdir("log_analyzer_json") do |dir|
      json_path = File.join(dir, "report.json")
      LogAnalyzer::Reporter.write_json(report, json_path)
      parsed_json = JSON.parse(File.read(json_path, encoding: "UTF-8"))

      assert_equal 13, parsed_json["total_lines"]
      assert_equal 2, parsed_json["malformed_lines"]
      assert_equal 5, parsed_json.dig("counts_by_level", "ERROR")
    end
  end

  def test_reporter_writes_csv_in_tmpdir
    report = LogAnalyzer::Analyzer.new(SAMPLE_LOG).analyze

    Dir.mktmpdir("log_analyzer_csv") do |dir|
      csv_path = File.join(dir, "report.csv")
      LogAnalyzer::Reporter.write_csv(report, csv_path)
      parsed_csv = CSV.read(csv_path, headers: true)

      assert_includes parsed_csv.headers, "category"
      assert(parsed_csv.any? { |row| row["category"] == "repeated_error" })
    end
  end

  def test_cli_runs_and_formats_json_output
    stdout = StringIO.new
    stderr = StringIO.new
    code = LogAnalyzer::CLI.run(["--format", "json", "--level", "FATAL", SAMPLE_LOG], stdout: stdout, stderr: stderr)

    assert_equal 0, code
    assert_empty stderr.string
    payload = JSON.parse(stdout.string)

    assert_equal 1, payload["matched_entries"]
  end
end
