# Lever
---

This is a little app designed to scan a directory and convert video files as necessary

It expects a directory structure where the video is contained in a folder with its name:
```
DirectoryToScan
├── AwesomeVideo
│   └── VIDEO
└── BlahVideo
    └── blah.iso
```

The videos can be stored in any HandBrake-able format; Lever will try to mount ISOs as well then HandBrake that dir.

Once Lever completes an encode it will move the resulting file to the original directory it scanned

---
### Setup
1. Clone the repo and run bundle install in the root of the project, you'll need to have ruby installed
2. Edit the config.yml with your specific info
  * Configure the handbrake command here; use the tokens %IF and %OF to specify the input and output file paths in the command respectively
    * Also the %OF should include the desired file extension, eg: ```%OF.mp4```
3. Edit database.yml with your specific info, Lever uses active_record so whatever works there should here too
4. Start the iso_mounter.rb
  * If on linux run as root since a super user is required to access loop devices for mounting ISOs
5. Start the main.rb as whatever user you want to have access to the required files
  * This will boot a webserver on whatever port you configured and start the system scanning
6. Check out the web ui to see what's up and if the system is functioning

---
### ISO Mounting

The ISO mounting capabilities are restricted to this daemon to ensure that the app is a bit more secure than having everything run as the super user

As such the iso mounter will only mount files from within the scan directory and it will only unmount directories from within the working directory. As such keep in mind where these directories are and don't put any important mounts in them for security reasons.
