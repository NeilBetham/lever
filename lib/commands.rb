module Commands
  def mount(target_iso, dest_dir)
    if Gem::Platform.local.os == 'linux'
      "mount -o loop #{target_iso} #{dest_dir}"
    elsif Gem::Platform.local.os == 'darwin'
      "hdiutil mount -mountpoint #{dest_dir} #{target_iso}"
    else
      ''
    end
  end

  def unmount(dir)
    "umount #{dir}"
  end

  def mkdir(dir)
    "mkdir #{dir}"
  end

  module_function :mount, :unmount, :mkdir
end
