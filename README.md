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

## Using ADB
Connect the Snapdragon Flightboard to the PC via USB. The following command will use ADB to upload the files:
```
make push-fastrtps
```

## Using SSH 
Alternatively, if you have an ssh access to the device you can create a writable space on the device as the linaro user:
```
# mkdir /upload
# chmod 777 /upload
```

Then on the PC:
```
make fastrtps.tgz
scp fastrtps.tgz linaro@${IP_ADDR_OF_TARGET}/upload
```

Then on the target:
```
cd /
tar tvzf /upload/fastrtps.tgz
```

# Running the HelloWorld example

# Installing Java
Make sure that you have an internet connection on the Snapdragon Flight board either via WiFi or a USB ethernet dongle. If you are using a USB Ethernet dongle then ADB won't work and you will have to either:
* ssh to the device as linaro and then sudo su
* use a serial console

Get a root shell on the device and install java support:
```
apt-get update
apt-get install openjdk-7-jdk
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
./binHelloWorldExample subscriber
```
