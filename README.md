# cross_fastrtps

Build Fast-RTPS and Fast-CDR for Snapdragon Flight

# Build Instructions

Make sure you have adb, cmake and gradle installed and that you have the Snapdragon Flight SDK set up
using https://github.com/ATLFlight/cross_toolchain

To build the files to install on the Snapdragn Flight board, run
```
make
```

# Install instructions

Connect the Snapdragon Flightboard to the PC via USB. The following command will use ADB to upload the files:
```
make debian-packages
make push-fastrtps
```

If the install of openjdk-7-jre-headless fails, you will have to get a root shell on the device and install java support.
Make sure that you have an internet connection on the Snapdragon Flight board either via WiFi or a USB ethernet dongle.
```
apt-get update
apt-get install openjdk-7-jre-headless
```

# Building HelloWorldExample
Now you can build the Helloworld example:
```
cd /usr/local/examples/C++/HelloWorldExample
fastrtpsgen -example i86Linux2.6gcc -replace HelloWorld.idl
make
```

# Running HelloWorldExample
Now you can run it:
```
./bin/HelloWorldExample publisher &
./bin/HelloWorldExample subscriber
```
