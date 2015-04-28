module Lever
  # Class to handle inspecting directories
  class Directory
    attr_reader :dir

    def initialize(directory)
      # Ruby is not recognizing direcotry string type
      # TODO: Charlock Holmes
      @dir = directory.force_encoding(Encoding::UTF_8)

      # Check if the directory is a full path or relative
      if Dir.exist? @dir
        # Probably a mounted ISO
        @sub_nodes = Dir.entries(@dir)
      else
        # Probably a directory out of the scan directory
        @sub_nodes = Dir.entries(File.join CONFIG['main']['scan_dir'], @dir)
      end

      @ignored = !get_ignores.empty?
      @encodes = get_encodes
      @isos = @encodes.grep(/.+\.iso/)
    end

    def encodeable?
      !@ignored && !@encodes.empty?
    end

    def iso?
      !@isos.empty?
    end

    def input_file
      return File.join(CONFIG['main']['scan_dir'], @dir, @isos.first) if iso?
      return File.join(CONFIG['main']['scan_dir'], @dir, @encodes.first)
    end

    def input_folder
      File.join CONFIG['main']['scan_dir'], @dir
    end

    def output_file
      File.join CONFIG['main']['working_dir'],
      File.basename(@dir, File.extname(@dir)).tr('^A-Za-z0-9', '') + CONFIG['main']['output_extension']
    end

    def get_ignores
      @sub_nodes.select do |node|
        !CONFIG['main']['ignore_if_present'].select do |extension|
          node =~ /#{extension}/
        end.empty?
      end.flatten.compact
    end

    def get_encodes
      @sub_nodes.select do |node|
        !CONFIG['main']['allowed_input_files'].select do |extension|
          node =~ /#{extension}/
        end.empty?
      end.flatten.compact
    end
  end
end
