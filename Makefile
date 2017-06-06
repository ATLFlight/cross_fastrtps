all: submodules fastrtps-arm-cross

TOPDIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ARMINSTALLDIR:=${TOPDIR}/arminstalldir

.PHONY: deps submodules clean push-fastrtps

# Set up the cross build environment via https://github.com/ATLFlight/cross_toolchain
define checkenv
	env | grep HEXAGON_SDK_ROOT || (echo "Error: Must set env var HEXAGON_SDK_ROOT" && false)
	env | grep HEXAGON_TOOLS_ROOT || (echo "Error: Must set env var HEXAGON_TOOLS_ROOT" && false)
	env | grep HEXAGON_ARM_SYSROOT || (echo "Error: Must set env var HEXAGON_ARM_SYSROOT" && false)
endef

deps:
	[ -f /usr/bin/gradle ] || (echo "Missing gradle: sudo apt-get install gradle" && false)
	[ -f /usr/bin/cmake ] || (echo "Missing cmake: sudo apt-get install cmake" && false)

submodules:
	git submodule update --init --recursive

clean:
	rm -rf ${ARMINSTALLDIR} build_fastrtps build_tinyxml2 build_fastcdr

${ARMINSTALLDIR}:
	mkdir -p $@

${ARMINSTALLDIR}/usr/local/lib/libtinyxml2.so: Fast-RTPS deps ${ARMINSTALLDIR}
	$(call checkenv)
	(mkdir -p build_tinyxml2)
	(cd build_tinyxml2 && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake ../Fast-RTPS/thirdparty/tinyxml2)
	(cd build_tinyxml2 && make VERBOSE=1 DESTDIR=${ARMINSTALLDIR} install)

${ARMINSTALLDIR}/usr/local/lib/libfastcdr.so: Fast-CDR deps cmake_hexagon ${ARMINSTALLDIR}
	$(call checkenv)
	mkdir -p build_fastcdr
	(cd build_fastcdr && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake ../Fast-CDR)
	(cd build_fastcdr && make DESTDIR=${ARMINSTALLDIR} install)

${ARMINSTALLDIR}/usr/local/lib/libfastrtps.so.1.4.0 fastrtps-arm-cross: ${ARMINSTALLDIR}/usr/local/lib/libtinyxml2.so deps cmake_hexagon
	$(call checkenv)
	mkdir -p build_fastrtps
	(cd build_fastrtps && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake -DTHIRDPARTY=ON -DBUILD_JAVA=ON -DASIO_INCLUDE_DIR=`pwd`/../Fast-RTPS/thirdparty/asio/asio/include -DTINYXML2_INCLUDE_DIR=`pwd`/../Fast-RTPS/thirdparty/tinyxml2 -DTINYXML2_LIBRARY=${ARMINSTALLDIR}/usr/local/lib/libtinyxml2.so ../Fast-RTPS)
	(cd build_fastrtps && make DESTDIR=${ARMINSTALLDIR} install)

push-fastrtps: ${ARMINSTALLDIR}/usr/local/lib/libfastcdr.so ${ARMINSTALLDIR}/usr/local/lib/libfastrtps.so.1.4.0
	(cd ${ARMINSTALLDIR} && find > ${TOPDIR}/fast-rtps-files)
	adb push ${ARMINSTALLDIR}/. /
	adb push fast-rtps-files /

fastrtps.tgz:
	(cd ${ARMINSTALLDIR} && tar -cvzf ${TOPDIR}/$@ .)
