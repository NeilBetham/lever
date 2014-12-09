# Lever
---

This is a little app designed to scan a directory and convert video files as necessary

It expects a directory structure where the video is contained in a folder with its name:
```
DirectoryToScan
├── Awesome Video
│   └── VIDEO
└── Blah Video
    └── blah.iso
```

The videos can be stored in any HandBrake-able format; Lever will try to mount ISOs aswell then HandBrake that dir.

---
### Setup
1. Edit the config.yml with your specific info
2. Edit database.yml with your specific info, Lever uses active_record so whatever works there shoudl here too
3. Linux requires root privilege to use loop devices for mounting ISOs so start the iso_mounter.rb as root
4. Start the main.rb which will boot a webserver on whatever port you configured and start the system scanning
5. Check out the web ui to see what's up and if the system is functioning
