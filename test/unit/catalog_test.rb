# frozen_string_literal: true

require "test_helper"

class CatalogTest < Minitest::Test
  def setup
    @catalog = RubyLab::Catalog.new
  end

  def test_discovers_all_fourteen_modules_in_order
    modules = @catalog.modules

    assert_equal 14, modules.size
    assert_equal "01_fundamentos", modules.first
    assert_equal "14_recursos_avanzados", modules.last
  end

  def test_filters_examples_by_module_prefix
    examples = @catalog.examples("01")

    assert_equal 7, examples.size
    assert(examples.all? { |entry| entry.group == "01_fundamentos" })
    assert_equal "01/01", examples.first.id
  end

  def test_finds_example_by_id_or_relative_path
    by_id = @catalog.find_example("01/01")
    by_path = @catalog.find_example("examples/01_fundamentos/01_sintaxis_y_convenciones.rb")

    refute_nil by_id
    assert_equal by_id, by_path
    assert_includes by_id.title, "Sintaxis"
    assert_nil @catalog.find_example("99/99")
  end

  def test_discovers_exercises_in_temporary_workspace
    Dir.mktmpdir("catalog_test") do |dir|
      FileUtils.mkdir_p(File.join(dir, "examples", "01_demo"))
      FileUtils.mkdir_p(File.join(dir, "exercises", "beginner"))
      File.write(File.join(dir, "examples", "01_demo", "01_sample.rb"), "# = Demo Ejemplo\nputs :ok\n")
      File.write(File.join(dir, "exercises", "beginner", "01_intro.md"), "# Ejercicio Uno\nTexto\n")

      custom_catalog = RubyLab::Catalog.new(root: dir)
      exercises = custom_catalog.exercises("beginner")

      assert_equal 1, exercises.size
      assert_equal "Ejercicio Uno", exercises.first.title
      assert_raises(ArgumentError) { custom_catalog.exercises("expert") }
    end
  end
end
