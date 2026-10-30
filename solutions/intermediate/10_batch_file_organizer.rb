# frozen_string_literal: true

# = Organizador de archivos por lotes con modo simulación (dry-run)

require "fileutils"
require "tmpdir"

module Solutions
  module Intermediate
    module BatchFileOrganizer
      CATEGORY_EXTENSIONS = {
        "images" => %w[.jpg .jpeg .png .gif .svg],
        "documents" => %w[.pdf .md .txt .csv .json],
        "code" => %w[.rb .py .js .ts .html .css]
      }.freeze

      EXTENSION_MAP = CATEGORY_EXTENSIONS.each_with_object({}) do |(cat, exts), map|
        exts.each { |ext| map[ext] = cat }
      end.freeze

      PlannedMove = Data.define(:file_name, :category, :source_path, :target_path, :executed)

      class Organizer
        attr_reader :root_dir

        def initialize(root_dir)
          raise ArgumentError, "Directory does not exist: #{root_dir}" unless Dir.exist?(root_dir.to_s)

          @root_dir = File.expand_path(root_dir)
        end

        def call(dry_run: false)
          candidate_files.map { |file_name| process_file(file_name, dry_run: dry_run) }
        end

        def self.category_for(file_name)
          ext = File.extname(file_name.to_s).downcase
          EXTENSION_MAP.fetch(ext, "others")
        end

        private

        def candidate_files
          Dir.children(@root_dir)
             .reject { |name| name.start_with?(".") }
             .select { |name| File.file?(File.join(@root_dir, name)) }
             .sort
        end

        def process_file(file_name, dry_run:)
          category = self.class.category_for(file_name)
          source_path = File.join(@root_dir, file_name)
          target_dir = File.join(@root_dir, category)
          target_path = File.join(target_dir, file_name)
          execute_move(source_path, target_dir, target_path) unless dry_run
          PlannedMove.new(
            file_name: file_name, category: category,
            source_path: source_path, target_path: target_path, executed: !dry_run
          )
        end

        def execute_move(source_path, target_dir, target_path)
          FileUtils.mkdir_p(target_dir)
          FileUtils.mv(source_path, target_path)
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Dir.mktmpdir do |dir|
    File.write(File.join(dir, "photo.jpg"), "img")
    File.write(File.join(dir, "notes.md"), "doc")
    organizer = Solutions::Intermediate::BatchFileOrganizer::Organizer.new(dir)
    puts organizer.call(dry_run: true).inspect
  end
end
