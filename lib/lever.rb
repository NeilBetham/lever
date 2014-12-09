module Lever
  def scan_movie_dir
    dir_to_scan = CONFIG['main']['scan_dir']

    # Scan all folders in directory
    dirs = Dir.entries(dir_to_scan).select do |entry|
      File.directory? File.join(dir_to_scan,entry) && !(entry == '.' || entry == '..' || entry =~ /^\./)
    end

    
  end
end
