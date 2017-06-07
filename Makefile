all: submodules fastcdr-arm-cross tinyxml2-arm-cross fastrtps-arm-cross debian-packages

TOPDIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
FASTRTPSINSTALLDIR:=${TOPDIR}/install/fastrtps
FASTCDRINSTALLDIR:=${TOPDIR}/install/fastcdr
TINYXMLINSTALLDIR:=${TOPDIR}/install/tinyxml2

.PHONY: deps submodules fastcdr-arm-cross tinyxml2-arm-cross fastrtps-arm-cross clean push-fastrtps debian-packages

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
	rm -rf ${TINYXMLINSTALLDIR} ${FASTRTPSINSTALLDIR} ${FASTCDRINSTALLDIR} builds/build_fastrtps builds/build_tinyxml2 builds/build_fastcdr
	rm -f package/*.deb
	rm -rf package/*/usr

${FASTRTPSINSTALLDIR} ${FASTCDRINSTALLDIR} ${TINYXMLINSTALLDIR}:
	mkdir -p $@

${TINYXMLINSTALLDIR}/usr/local/lib/libtinyxml2.so tinyxml2-arm-cross: Fast-RTPS deps ${TINYXMLINSTALLDIR}
	$(call checkenv)
	(mkdir -p builds/build_tinyxml2)
	(cd builds/build_tinyxml2 && cmake -DCMAKE_TOOLCHAIN_FILE=${TOPDIR}/cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake ${TOPDIR}/Fast-RTPS/thirdparty/tinyxml2)
	(cd builds/build_tinyxml2 && make VERBOSE=1 DESTDIR=${TINYXMLINSTALLDIR} install)
	mkdir -p ${TINYXMLINSTALLDIR}/usr/local/share/doc/tinyxml2
	sed -n '286,1000p' Fast-RTPS/thirdparty/tinyxml2/readme.md > ${TINYXMLINSTALLDIR}/usr/local/share/doc/tinyxml2/copyright

${FASTCDRINSTALLDIR}/usr/local/lib/libfastcdr.so fastcdr-arm-cross: Fast-CDR deps cmake_hexagon ${FASTCDRINSTALLDIR}
	$(call checkenv)
	mkdir -p builds/build_fastcdr
	(cd builds/build_fastcdr && cmake -DCMAKE_TOOLCHAIN_FILE=${TOPDIR}/cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake ${TOPDIR}/Fast-CDR)
	(cd builds/build_fastcdr && make DESTDIR=${FASTCDRINSTALLDIR} install)
	mkdir -p ${FASTCDRINSTALLDIR}/usr/local/share/doc/fastcdr

${FASTRTPSINSTALLDIR}/usr/local/lib/libfastrtps.so.1.4.0 fastrtps-arm-cross: ${TINYXMLINSTALLDIR}/usr/local/lib/libtinyxml2.so deps cmake_hexagon
	$(call checkenv)
	mkdir -p builds/build_fastrtps
	(cd builds/build_fastrtps && cmake -DCMAKE_TOOLCHAIN_FILE=${TOPDIR}/cmake_hexagon/toolchain/Toolchain-arm-linux-gnueabihf.cmake -DTHIRDPARTY=ON -DBUILD_JAVA=ON -DASIO_INCLUDE_DIR=${TOPDIR}/Fast-RTPS/thirdparty/asio/asio/include -DTINYXML2_INCLUDE_DIR=${TOPDIR}/Fast-RTPS/thirdparty/tinyxml2 -DTINYXML2_LIBRARY=${TINYXMLINSTALLDIR}/usr/local/lib/libtinyxml2.so ${TOPDIR}/Fast-RTPS)
	(cd builds/build_fastrtps && make DESTDIR=${FASTRTPSINSTALLDIR} install)
	mkdir -p ${FASTRTPSINSTALLDIR}/usr/local/share/doc/fastrtps
	mv ${FASTRTPSINSTALLDIR}/usr/local/share/fastrtps/LICENSE ${FASTRTPSINSTALLDIR}/usr/local/share/doc/fastrtps/LICENSE


# Install options
#
# The packages can be installed via adb

# Using dpkg-deb --build to create simple, uninstallable packages
debian-packages: package/libtinyxml2-4-dev_4.0.1-1_armhf.deb package/libtinyxml2-4_4.0.1-1_armhf.deb \
	package/libfastrtps-dev_0.1_armhf.deb package/libfastrtps_0.1_armhf.deb \
	package/libfastcdr-dev_0.1_armhf.deb package/libfastcdr_0.1_armhf.deb \
	package/usr-local-lib_0.1_armhf.deb

push-fastrtps: debian-packages
	adb shell rm -rf /upload
	adb shell mkdir -p /upload
	adb push package/libtinyxml2-4-dev_4.0.1-1_armhf.deb /upload
	adb push package/libtinyxml2-4_4.0.1-1_armhf.deb /upload
	adb push package/libfastrtps-dev_0.1_armhf.deb /upload
	adb push package/libfastrtps_0.1_armhf.deb /upload
	adb push package/libfastcdr-dev_0.1_armhf.deb /upload
	adb push package/libfastcdr_0.1_armhf.deb /upload
	adb push package/usr-local-lib_0.1_armhf.deb /upload
	adb shell dpkg -i /upload/*.deb

#fastrtps.tgz:
#	(cd ${FASTRTPSINSTALLDIR} && tar -cvzf ${TOPDIR}/$@ .)
#	(cd ${FASTCDRINSTALLDIR} && tar -avzf ${TOPDIR}/$@ .)
#	(cd ${TINYXMLINSTALLDIR} && tar -avzf ${TOPDIR}/$@ .)


package/libtinyxml2-4-dev_4.0.1-1_armhf.deb:
	@rm -rf $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr
	@cp -ar ${TINYXMLINSTALLDIR}/* $(patsubst %_4.0.1-1_armhf.deb,%,$@)
	@rm -f $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr/local/lib/*.so.*
	dpkg-deb --build $(patsubst %_4.0.1-1_armhf.deb,%,$@) $@

package/libtinyxml2-4_4.0.1-1_armhf.deb:
	@rm -rf $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr
	@mkdir -p $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr/local/lib
	@mkdir -p $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr/local/share/doc/libtinyxml2-4
	@cp -ap ${TINYXMLINSTALLDIR}/usr/local/lib/*.so.* $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr/local/lib
	@cp -ap ${TINYXMLINSTALLDIR}/usr/local/share/doc/tinyxml2/* $(patsubst %_4.0.1-1_armhf.deb,%,$@)/usr/local/share/doc/libtinyxml2-4/
	dpkg-deb --build $(patsubst %_4.0.1-1_armhf.deb,%,$@) $@

package/libfastrtps-dev_0.1_armhf.deb:
	@rm -rf $(patsubst %_0.1_armhf.deb,%,$@)/usr
	@cp -av ${FASTRTPSINSTALLDIR}/. $(patsubst %_0.1_armhf.deb,%,$@)
	@rm -f $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/lib/*.so.*
	@mv $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/share/doc/fastrtps $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/share/doc/libfastrtps-dev
	dpkg-deb --build $(patsubst %_0.1_armhf.deb,%,$@) $@

package/libfastrtps_0.1_armhf.deb:
	@rm -rf $(patsubst %_0.1_armhf.deb,%,$@)/usr
	@mkdir -p $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/lib
	@mkdir -p $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/share/doc/libfastrtps
	@cp -av ${FASTRTPSINSTALLDIR}/usr/local/lib/*.so.* $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/lib/
	@cp -av ${FASTRTPSINSTALLDIR}/usr/local/share/doc/fastrtps/* $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/share/doc/libfastrtps/
	dpkg-deb --build $(patsubst %_0.1_armhf.deb,%,$@) $@

package/libfastcdr-dev_0.1_armhf.deb:
	@rm -rf $(patsubst %_0.1_armhf.deb,%,$@)/usr
	@cp -av ${FASTCDRINSTALLDIR}/. $(patsubst %_0.1_armhf.deb,%,$@)
	@rm -f $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/lib/*.so.*
	@mv $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/share/doc/fastcdr $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/share/doc/libfastcdr-dev
	dpkg-deb --build $(patsubst %_0.1_armhf.deb,%,$@) $@

package/libfastcdr_0.1_armhf.deb:
	@rm -rf $(patsubst %_0.1_armhf.deb,%,$@)/usr
	@mkdir -p $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/lib
	@mkdir -p $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/share/doc/libfastcdr
	@cp -av ${FASTCDRINSTALLDIR}/usr/local/lib/*.so.* $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/lib/
	@cp -av ${FASTCDRINSTALLDIR}/usr/local/share/fastcdr/* $(patsubst %_0.1_armhf.deb,%,$@)/usr/local/share/doc/libfastcdr/
	dpkg-deb --build $(patsubst %_0.1_armhf.deb,%,$@) $@

package/usr-local-lib_0.1_armhf.deb:
	dpkg-deb --build $(patsubst %_0.1_armhf.deb,%,$@) $@
