module Lever
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
      next if Job.where(name: dir.dir).count > 0
      next unless dir.encodeable?

      if dir.iso?
        # Mount the iso and check the to make sure we have something to encode
        ISO.mount(dir.input_file)
        .errback { error 'failed to mount ISO for inspection' }
        .callback do |data|
          mounted_iso = data['path']

          # Setup directory inspector
          iso_dir = Lever::Directory.new mounted_iso

          # Create job with orignal dir inspection so we force it to be remounted
          if iso_dir.encodeable?
            Job.create(
              name: dir.dir,
              input_folder: dir.input_folder,
              input_file_name: dir.input_file,
              output_file_name: dir.output_file,
              state: 'queued',
              iso: dir.iso?
            )
          end

          # Unmount ISO
          ISO.unmount(mounted_iso)
            .errback { |error| error "failed to unmount ISO, #{error}" }
        end

        # If the iso is mounted and if the iso has files to encode
        next
      end

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
