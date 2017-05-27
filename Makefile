all: submodules install_fastrtps

define checkenv
	env | grep HEXAGON_SDK_ROOT || (echo "Error: Must set env var HEXAGON_SDK_ROOT" && false)
	env | grep HEXAGON_TOOLS_ROOT || (echo "Error: Must set env var HEXAGON_TOOLS_ROOT" && false)
	env | grep HEXAGON_ARM_SYSROOT || (echo "Error: Must set env var HEXAGON_ARM_SYSROOT" && false)
endef

submodules:
	git submodule update --init --recursive

build_tinyxml2/libtinyxml2.so:
	$(call checkenv)
	sed -i -e "s/^# Add targets/SET_PROPERTY(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)/" Fast-RTPS/thirdparty/tinyxml2/CMakeLists.txt 
	mkdir -p build_tinyxml2
	(cd build_tinyxml2 && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake ../Fast-RTPS/thirdparty/tinyxml2)
	(cd build_tinyxml2 && make)

installdir/usr/local/lib/libtinyxml2.so: build_tinyxml2/libtinyxml2.so installdir
	(cd build_tinyxml2 && make  DESTDIR=`pwd`/../installdir install)

installdir:
	mkdir -p installdir

build_fastrtps/src/cpp/libfastrtps.so: installdir/usr/local/lib/libtinyxml2.so
	$(call checkenv)
	sed -i -e "s/^check_endianness()/SET(__BIG_ENDIAN__ 0)/" Fast-RTPS/CMakeLists.txt 
	sed -i -e "s/^# Test system configuration/SET_PROPERTY(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)/" Fast-RTPS/CMakeLists.txt 
	sed -i -e "s/    find_package(Threads REQUIRED)/#/" Fast-RTPS/src/cpp/CMakeLists.txt 
	mkdir -p build_fastrtps
	(cd build_fastrtps && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake -DTHIRDPARTY=ON -DBUILD_JAVA=ON -DASIO_INCLUDE_DIR=`pwd`/../Fast-RTPS/thirdparty/asio/asio/include -DTINYXML2_INCLUDE_DIR=`pwd`/../installdir/usr/local/include -DTINYXML2_SOURCE_DIR=`pwd`/../Fast-RTPS/thirdparty/tinyxml2 -DTINYXML2_LIBRARY=`pwd`/../installdir/usr/local/lib/libtinyxml2.so ../Fast-RTPS)
	(cd build_fastrtps && make)

install_fastrtps: build_fastrtps/src/cpp/libfastrtps.so
	(cd build_fastrtps && make DESTDIR=`pwd`/../installdir install)

clean:
	rm -rf installdir
	rm -rf build_tinyxml2
	rm -rf build_fastrtps

