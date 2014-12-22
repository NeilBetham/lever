module Lever
  def scan_dir
    dir_to_scan = CONFIG['main']['scan_dir']

    # Scan all folders in directory
    dirs = Dir.entries(dir_to_scan).select do |entry|
      File.directory?(File.join(dir_to_scan,entry)) && !(entry == '.' || entry == '..' || entry =~ /^\./)
    end

    # Check if dir should be ignored
    dirs.each do |dir|
      Dir.entries(File.join CONFIG['main']['scan_dir'], dir).select do |entry|
        CONFIG['main']['ignore_if_present'].each do |extension|
          if entry =~ /#{extension}/
            dirs.delete(dir)
          end
        end
      end
    end

    # Schedule the remaining directories for encoding
    dirs.each do |dir|
      output_file = File.basename(dir, File.extname(dir)).tr('^A-Za-z0-9', '') + CONFIG['main']['output_extension']

      iso = Dir.glob("#{File.join CONFIG['main']['scan_dir'], dir}/*.iso")

      if !iso.empty?
        input_file_folder = iso[0]
      else
        input_file_folder = File.join CONFIG['main']['scan_dir'], dir
      end

      if Job.where(name: dir).count > 0
        next
      end

      Job.create(
        name: dir,
        input_folder: input_file_folder,
        output_file_name: output_file,
        state: 'queued',
        iso: !iso.empty?
      )
    end
  end

  module_function :scan_dir
end
