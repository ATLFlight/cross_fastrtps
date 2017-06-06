all: submodules fastcdr-arm-cross tinyxml2-arm-cross fastrtps-arm-cross 

TOPDIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
FASTRTPSINSTALLDIR:=${TOPDIR}/fastrtpsinstalldir
FASTCDRINSTALLDIR:=${TOPDIR}/fastcdrinstalldir
TINYXMLINSTALLDIR:=${TOPDIR}/tinyxml2installdir

.PHONY: deps submodules fastcdr-arm-cross tinyxml2-arm-cross fastrtps-arm-cross clean push-fastrtps

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
	rm -rf ${FASTRTPSINSTALLDIR} ${FASTCDRINSTALLDIR} build_fastrtps build_tinyxml2 build_fastcdr
	rm -f *.deb

${FASTRTPSINSTALLDIR} ${FASTCDRINSTALLDIR} ${TINYXMLINSTALLDIR}:
	mkdir -p $@

${TINYXMLINSTALLDIR}/usr/local/lib/libtinyxml2.so tinyxml2-arm-cross: Fast-RTPS deps ${TINYXMLINSTALLDIR}
	$(call checkenv)
	(mkdir -p build_tinyxml2)
	(cd build_tinyxml2 && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake ../Fast-RTPS/thirdparty/tinyxml2)
	(cd build_tinyxml2 && make VERBOSE=1 DESTDIR=${TINYXMLINSTALLDIR} install)
	mkdir -p ${TINYXMLINSTALLDIR}/usr/local/share/doc/tinyxml2
	sed -n '286,1000p' Fast-RTPS/thirdparty/tinyxml2/readme.md > ${TINYXMLINSTALLDIR}/usr/local/share/doc/tinyxml2/copyright

${FASTCDRINSTALLDIR}/usr/local/lib/libfastcdr.so fastcdr-arm-cross: Fast-CDR deps cmake_hexagon ${FASTCDRINSTALLDIR}
	$(call checkenv)
	mkdir -p build_fastcdr
	(cd build_fastcdr && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake ../Fast-CDR)
	(cd build_fastcdr && make DESTDIR=${FASTCDRINSTALLDIR} install)
	mkdir -p ${FASTCDRINSTALLDIR}/usr/local/share/doc/fastcdr
	cp Fast-CDR/LICENSE ${FASTCDRINSTALLDIR}/usr/local/share/doc/fastcdr/LICENSE

${FASTRTPSINSTALLDIR}/usr/local/lib/libfastrtps.so.1.4.0 fastrtps-arm-cross: ${TINYXMLINSTALLDIR}/usr/local/lib/libtinyxml2.so deps cmake_hexagon
	$(call checkenv)
	mkdir -p build_fastrtps
	(cd build_fastrtps && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake -DTHIRDPARTY=ON -DBUILD_JAVA=ON -DASIO_INCLUDE_DIR=`pwd`/../Fast-RTPS/thirdparty/asio/asio/include -DTINYXML2_INCLUDE_DIR=`pwd`/../Fast-RTPS/thirdparty/tinyxml2 -DTINYXML2_LIBRARY=${TINYXMLINSTALLDIR}/usr/local/lib/libtinyxml2.so ../Fast-RTPS)
	(cd build_fastrtps && make DESTDIR=${FASTRTPSINSTALLDIR} install)
	mkdir -p ${FASTRTPSINSTALLDIR}/usr/local/share/doc/fastrtps
	mv ${FASTRTPSINSTALLDIR}/usr/local/share/fastrtps/LICENSE ${FASTRTPSINSTALLDIR}/usr/local/share/doc/fastrtps/LICENSE


# Install options
#
# The files can be installed via adb, scp of a tar.gz, or as a Debian package
push-fastrtps: ${FASTCDRINSTALLDIR}/usr/local/lib/libfastcdr.so ${FASTRTPSINSTALLDIR}/usr/local/lib/libfastrtps.so.1.4.0
	(cd ${TINYXMLINSTALLDIR} && find > ${TOPDIR}/fast-cdr-files)
	adb push ${TINYXMLINSTALLDIR}/. /
	(cd ${FASTRTPSINSTALLDIR} && find > ${TOPDIR}/fast-rtps-files)
	adb push ${FASTRTPSINSTALLDIR}/. /
	(cd ${FASTCDRINSTALLDIR} && find > ${TOPDIR}/fast-cdr-files)
	adb push ${FASTCDRINSTALLDIR}/. /
	adb push fast-cdr-files /

fastrtps.tgz:
	(cd ${FASTRTPSINSTALLDIR} && tar -cvzf ${TOPDIR}/$@ .)
	(cd ${FASTCDRINSTALLDIR} && tar -avzf ${TOPDIR}/$@ .)
	(cd ${TINYXMLINSTALLDIR} && tar -avzf ${TOPDIR}/$@ .)

#	cp README.Debian ${FASTRTPSINSTALLDIR}/usr/local/share/fast-rtps/README.Debian

package/libtinyxml2-dev_4.0.1-1_armhf.deb:
	rm -rf $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr
	(cp -ar ${TINYXMLINSTALLDIR}/* $(patsubst %_4.0.1-1_armhf.deb,%,$@))
	rm $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr/local/lib/*.so.*
	(dpkg-deb --build $(patsubst %_4.0.1-1_armhf.deb,%,$@) $@)

#	mkdir -p $(patsubst %_4.0.1-1_armhf.deb,%,$@)
#(mv $(patsubst %_4.0.1-1_armhf.deb,%.deb,$@) $@)

fastrtps-dev_0.1_armhf.deb:
	dpkg-deb --build $(patsubst %_0.1_armhf.deb,%,$@)
	mv $(patsubst %_0.1_armhf.deb,%.deb,$@) $@
