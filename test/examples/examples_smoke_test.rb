# frozen_string_literal: true

require "test_helper"

# Prueba de humo: cada ejemplo de examples/ debe ejecutarse de forma
# independiente, sin entrada por teclado, y terminar con éxito.
#
# Se genera un test por archivo para que un fallo indique exactamente qué
# ejemplo se rompió.
class ExamplesSmokeTest < Minitest::Test
  EXAMPLE_FILES = Dir.glob(File.join(TestSupport::ROOT, "examples", "**", "*.rb")).sort.freeze

  def test_examples_are_discovered
    assert_operator EXAMPLE_FILES.size, :>=, 14, "Se esperaba al menos un ejemplo por módulo"
  end

  EXAMPLE_FILES.each do |path|
    relative = path.delete_prefix("#{TestSupport::ROOT}/")
    test_name = "test_runs_#{relative.gsub(/[^a-z0-9]+/i, '_')}"

    define_method(test_name) do
      stdout, stderr, status = TestSupport.run_ruby(path)

      assert_predicate status, :success?, "#{relative} falló:\n#{stderr}"
      refute_empty stdout.strip, "#{relative} no produjo salida"
    end
  end
end
