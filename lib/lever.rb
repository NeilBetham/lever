module Lever
  # Class to handle inspecting directories
  class Directory
    attr_reader :dir

    def initialize(directory)
      @dir = directory
      @sub_nodes = Dir.entries(File.join CONFIG['main']['scan_dir'], @dir)

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
      File.join CONFIG['main']['scan_dir'],
                @dir,
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

  def scan_dir
    dir_to_scan = CONFIG['main']['scan_dir']

    # Scan all folders in directory
    dirs = Dir.entries(dir_to_scan).select do |entry|
      File.directory?(File.join(dir_to_scan,entry)) && !(entry == '.' || entry == '..' || entry =~ /^\./)
    end

    # Setup directory objects
    dirs = dirs.map do |dir|
      Directory.new(dir)
    end

    # Schedule the remaining directories for encoding
    dirs.each do |dir|
      next if Job.where(name: dir.input_folder).count > 0
      next unless dir.encodeable?

      Job.create(
        name: dir.dir,
        input_folder: dir.input_folder,
        input_file_name: dir.input_file,
        output_file_name: dir.output_file,
        state: 'queued',
        iso: dir.iso?
      )
    end
  end

  module_function :scan_dir
end
