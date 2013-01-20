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

P=qt
P_V=qt-everywhere-opensource-src-${QT_VERSION}
SRC_FILE="${P_V}.tar.gz"
URL=http://releases.qt-project.org/qt4/source/$SRC_FILE
DEPENDS=()

change_paths() {
	export INCLUDE="$MINGWHOME/$HOST/include:$PREFIX/include:$PREFIX/include/libxml2:$QTDIR/databases/firebird/include:$QTDIR/databases/mysql/include/mysql:$QTDIR/databases/pgsql/include"
	export LIB="$MINGWHOME/$HOST/lib:$PREFIX/lib:$QTDIR/databases/firebird/lib:$QTDIR/databases/mysql/lib:$QTDIR/databases/pgsql/lib"
	OLD_PATH=$PATH
	export PATH=$MINGW_PART_PATH:$BUILD_DIR/$P-$QT_VERSION/bin:$WINDOWS_PART_PATH:$MSYS_PART_PATH
}

restore_paths() {
	unset INCLUDE
	unset LIB
	export PATH=$OLD_PATH
	unset OLD_PATH
}

src_download() {
	func_download $P_V ".tar.gz" $URL
}

src_unpack() {
	func_uncompress $P_V ".tar.gz" $BUILD_DIR

	if [ -d $BUILD_DIR/$P_V ]
	then 
		mv $BUILD_DIR/$P_V $BUILD_DIR/$P-$QT_VERSION
	fi
}

src_patch() {
	local _patches=(
		$P/4.8.x/qt-4.6-demo-plugandpaint.patch
		$P/4.8.x/qt-4.8.0-dont-perform-ipc-checks-for-win32.patch
		$P/4.8.x/qt-4.8.0-fix-include-windows-h.patch
		$P/4.8.x/qt-4.8.0-fix-javascript-jit-on-mingw-x86_64.patch
		$P/4.8.x/qt-4.8.0-fix-mysql-driver-build.patch
		$P/4.8.x/qt-4.8.0-no-webkit-tests.patch
		$P/4.8.x/qt-4.8.0-use-fbclient-instead-gds32.patch
		$P/4.8.x/qt-4.8.1-fix-activeqt-compilation.patch
		$P/4.8.x/qt-4.8.2-javascriptcore-x32.patch
		$P/4.8.x/qt-4.8.3-assistant-4.8.2+gcc-4.7.patch
		$P/4.8.x/qt-4.8.3-qmake-cmd-mkdir-slash-direction.patch
		$P/4.8.x/qt-4.8.x-win32-g++-mkspec-optimization.patch	
	)
	
	func_apply_patches \
		$P-$QT_VERSION \
		_patches[@] \
		$BUILD_DIR
	
	pushd $BUILD_DIR/$P-$QT_VERSION/mkspecs/win32-g++ > /dev/null
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
	
	if ! [ -d ${QTDIR}/databases ]
	then
		mkdir -p ${QTDIR}/databases
		cp -rf ${PATCH_DIR}/${P}/databases-${ARCHITECTURE}/* ${QTDIR}/databases/
	fi
}

src_configure() {
	pushd $BUILD_DIR/$P-$QT_VERSION > /dev/null
	if [ -f configure.marker ]
	then
		echo "--> configured"
	else
		echo -n "--> configure..."
	
		change_paths
	
		configure.exe \
			-prefix $QTDIR_WIN \
			-opensource \
			-confirm-license \
			-debug-and-release \
			-plugin-sql-ibase \
			-plugin-sql-mysql \
			-plugin-sql-psql \
			-no-dbus \
			-stl \
			-no-dsp \
			-no-vcproj \
			-exceptions \
			-openssl \
			-platform win32-g++-4.6 \
			-nomake demos \
			-nomake examples \
			-I $MINGWHOME/$HOST/include \
			-I $PREFIX/include \
			-I $PREFIX/include/libxml2 \
			-I $QTDIR/databases/firebird/include \
			-I $QTDIR/databases/mysql/include/mysql \
			-I $QTDIR/databases/pgsql/include \
			-L $MINGWHOME/$HOST/lib \
			-L $PREFIX/lib \
			-L $QTDIR/databases/firebird/lib \
			-L $QTDIR/databases/mysql/lib \
			-L $QTDIR/databases/pgsql/lib \
			> ${LOG_DIR}/${P_V}_configure.log 2>&1 || exit 1
	
		restore_paths
		cp -rf mkspecs $QTDIR/
		echo " done"
	fi
	touch configure.marker
	
	popd > /dev/null
}

pkg_build() {
	# Workaround for QtWebkit linking
	pushd $BUILD_DIR/$P-$QT_VERSION/src/3rdparty/webkit/Source/WebKit/qt/declarative > /dev/null
	if [ -f workaround.marker ]
	then
		echo "--> Workaround applied"
	else
		echo -n "--> Applying workaround..."
		$BUILD_DIR/$P-$QT_VERSION/bin/qmake declarative.pro || die "QMake failed"
		echo " done"
		touch workaround.marker
	fi
	popd > /dev/null

	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		$P-$QT_VERSION \
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
		$P-$QT_VERSION \
		"mingw32-make" \
		"$_allinstall" \
		"installing..." \
		"installed"
	
	restore_paths
}
