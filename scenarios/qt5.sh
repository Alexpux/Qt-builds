#!/bin/bash

#
# The BSD 3-Clause License. http://www.opensource.org/licenses/BSD-3-Clause
#
# This file is part of 'Qt-builds' project.
# Copyright (c) 2013 by Alexpux (alexpux@gmail.com)
# All rights reserved.
#
# Project: Qt-builds ( https://github.com/Alexpux/Qt-builds )
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the distribution.
# - Neither the name of the 'Qt-builds' nor the names of its contributors may
#     be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# **************************************************************************

P=qt5
P_V=qt-everywhere-opensource-src-${QT5_VERSION}
SRC_FILE="${P_V}.tar.gz"
URL=http://releases.qt-project.org/qt5/${QT5_VERSION}/single/$SRC_FILE
DEPENDS=(gperf icu fontconfig freetype libxml2 libxslt pcre perl ruby)

change_paths() {
	export INCLUDE="$MINGWHOME/$HOST/include:$PREFIX/include:$PREFIX/include/libxml2:$QT5DIR/databases/firebird/include:$QT5DIR/databases/mysql/include/mysql:$QT5DIR/databases/pgsql/include"
	export LIB="$MINGWHOME/$HOST/lib:$PREFIX/lib:$QT5DIR/databases/firebird/lib:$QT5DIR/databases/mysql/lib:$QT5DIR/databases/pgsql/lib"
	export DXSDK_DIR="C:/Program Files (x86)/Microsoft DirectX SDK (June 2010)/"
	OLD_PATH=$PATH
	export PATH=$BUILD_DIR/$P/$P_V/gnuwin32/bin:$BUILD_DIR/$P/$P_V/qtbase/bin:$MINGW_PART_PATH:$PREFIX/perl/bin:$WINDOWS_PART_PATH:$MSYS_PART_PATH
}

restore_paths() {
	unset INCLUDE
	unset LIB
	unset DXSDK_DIR
	export PATH=$OLD_PATH
	unset OLD_PATH
}

src_download() {
	func_download $P_V ".tar.gz" $URL
}

src_unpack() {
	func_uncompress $P_V ".tar.gz"
}

src_patch() {
	local _patches=(
		$P/01-ANGLE-always-use-DEF_FILE-on-Windows.patch
		$P/02-ANGLE-fix-typedefs.patch
		$P/03-ANGLE-fix-linking-on-mingw.patch
		$P/031-ANGLE-fix-linking-on-mingw64.patch
		$P/04-fix-undefined-reference-to-JSC-JSCell-classinfo-with-mingw.patch
		$P/05-fix-math-pow-implementation-for-mingw-w64.patch
		$P/06-use-fbclient-instead-of-gds32.patch
		$P/07-qtwebkit-fix-libxml2-test.patch
		$P/08-build-under-msys.patch
		#$P/09-mingw-gcc-4.7.2.patch
		$P/010-win32-g++-mkspec.patch
		$P/011-fix-linking-order.patch
		$P/012-qt5-webkit-pkgconfig-link-windows.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
		
	touch $SRC_DIR/$P_V/qtbase/.gitignore
	
	pushd $SRC_DIR/$P_V/qtbase/mkspecs/win32-g++ > /dev/null
		if [ -f qmake.conf.patched ]
		then
			rm -f qmake.conf
			cp -f qmake.conf.patched qmake.conf
		else
			cp -f qmake.conf qmake.conf.patched
		fi
		
		cat qmake.conf | sed 's|%OPTIMIZE_OPT%|'"$OPTIM"'|g' > qmake.conf.tmp
		rm -f qmake.conf
		mv qmake.conf.tmp qmake.conf
	popd > /dev/null
	
	mkdir -p ${QT5DIR}/databases
	cp -rf ${PATCH_DIR}/${P}/databases-${ARCHITECTURE}/* ${QT5DIR}/databases/
}

src_configure() {
	mkdir -p $BUILD_DIR/$P-$QT5_VERSION
	pushd $BUILD_DIR/$P-$QT5_VERSION > /dev/null
	if [ -f configure.marker ]
	then
		echo n "--> configured"
	else
		echo -n "--> configure..."
		local _rel_path=$( func_absolute_to_relative $BUILD_DIR/$P-$QT5_VERSION $SRC_DIR/$P_V )
	
		change_paths
	
		$PREFIX/perl/bin/perl $_rel_path/configure \
			-prefix $QT5DIR_WIN \
			-opensource \
			-confirm-license \
			-debug-and-release \
			-plugin-sql-ibase \
			-plugin-sql-mysql \
			-plugin-sql-psql \
			-no-dbus \
			-no-iconv \
			-icu \
			-fontconfig \
			-system-pcre \
			-system-zlib \
			-openssl \
			-opengl desktop \
			-platform win32-g++ \
			-nomake tests \
			-nomake examples \
			> ${LOG_DIR}/${P_V}_configure.log 2>&1 || exit 1
	
		restore_paths
		echo " done"
	fi
	touch configure.marker
	popd > /dev/null
}

pkg_build() {
	change_paths
	
	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		$P-$QT5_VERSION \
		"mingw32-make" \
		"$_allmake" \
		"building..." \
		"built"

	restore_paths
}

pkg_install() {
	change_paths
	
	local _install_flags=(
		${MAKE_OPTS}
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		$P-$QT5_VERSION \
		"mingw32-make" \
		"$_allinstall" \
		"installing..." \
		"installed"
	
	restore_paths
}
