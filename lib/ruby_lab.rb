# frozen_string_literal: true

require_relative "ruby_lab/version"
require_relative "ruby_lab/catalog"
require_relative "ruby_lab/cli"

# Punto de entrada de la librería de soporte del laboratorio.
#
# La librería es deliberadamente pequeña: descubre ejemplos y ejercicios a
# partir del sistema de archivos y ofrece una CLI para navegarlos. El contenido
# didáctico vive en examples/, exercises/, solutions/ y case_studies/.
module RubyLab
  # Raíz del repositorio, calculada a partir de este archivo para no depender
  # del directorio de trabajo actual.
  def self.root
    File.expand_path("..", __dir__)
  end
end
