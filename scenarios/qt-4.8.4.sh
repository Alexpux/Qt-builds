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
	export INCLUDE="$MINGWHOME/$HOST/include:$PREFIX/include:$PREFIX/include/libxml2:$QTDIR/databases/firebird/include:$QTDIR/databases/mysql/include/mysql:$QTDIR/databases/pgsql/include:$QTDIR/databases/oci/include"
	export LIB="$MINGWHOME/$HOST/lib:$PREFIX/lib:$QTDIR/databases/firebird/lib:$QTDIR/databases/mysql/lib:$QTDIR/databases/pgsql/lib:$QTDIR/databases/oci/lib"
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

	if [ -f $BUILD_DIR/$P-$QT_VERSION/configure.marker ]
	then
		echo "--> configured"
	else
		pushd $BUILD_DIR/$P-$QT_VERSION > /dev/null
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
			-plugin-sql-oci \
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
			-I $QTDIR/databases/oci/include \
			-L $MINGWHOME/$HOST/lib \
			-L $PREFIX/lib \
			-L $QTDIR/databases/firebird/lib \
			-L $QTDIR/databases/mysql/lib \
			-L $QTDIR/databases/pgsql/lib \
			-L $QTDIR/databases/oci/lib \
			> ${LOG_DIR}/${P_V}_configure.log 2>&1 || die "Qt configure error"
	
		restore_paths
		cp -rf mkspecs $QTDIR/
		echo " done"
		touch configure.marker
		popd > /dev/null
	fi
}

pkg_build() {
	# Workaround for QtWebkit linking
	change_paths
	
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
	private_headers

	if ! [ -f $BUILD_DIR/$P-$QT_VERSION/qt-conf.marker ]
	then
		cat $PATCH_DIR/$P/qt.conf | sed 's|%PREFIX%|'"$QTDIR_WIN"'|g' \
			 > $QTDIR/bin/qt.conf
		touch $BUILD_DIR/$P-$QT_VERSION/qt-conf.marker
	fi
}

private_headers() {

	if ! [ -f $BUILD_DIR/$P-$QT_VERSION/private_headers.marker ]
	then
		pushd $BUILD_DIR/$P-$QT_VERSION > /dev/null
		echo "--> Install private headers"

		local PRIVATE_HEADERS=(
			phonon
			Qt3Support
			QtCore
			QtDBus
			QtDeclarative
			QtDesigner
			QtGui
			QtHelp
			QtMeeGoGraphicsSystemHelper
			QtMultimedia
			QtNetwork
			QtOpenGl
			QtOpenVG
			QtScript
			QtScriptTools
			QtSql
			QtSvg
			QtTest
			QtUiTools
			QtWebkit
			QtXmlPatterns
		)

		for priv_headers in ${PRIVATE_HEADERS[@]}
		do
			mkdir -p ${QTDIR}/include/${priv_headers}
			mkdir -p ${QTDIR}/include/${priv_headers}/private
		done

		echo "---> Qt3Support"
		cp -rfv `find src/qt3support -type f -name "*_p.h"` ${QTDIR}/include/Qt3Support/private > priv_headers.log 2>&1
		cp -rfv `find src/qt3support -type f -name "*_pch.h"` ${QTDIR}/include/Qt3Support/private >> priv_headers.log 2>&1

		echo "---> QtCore"
		cp -rfv `find src/corelib -type f -name "*_p.h"` ${QTDIR}/include/QtCore/private >> priv_headers.log 2>&1
		cp -rfv `find src/corelib -type f -name "*_pch.h"` ${QTDIR}/include/QtCore/private >> priv_headers.log 2>&1

		echo "---> QtDBus"
		cp -rfv `find src/dbus -type f -name "*_p.h"` ${QTDIR}/include/QtDBus/private >> priv_headers.log 2>&1

		echo "---> QtDeclarative"
		cp -rfv `find src/declarative -type f -name "*_p.h"` ${QTDIR}/include/QtDeclarative/private >> priv_headers.log 2>&1

		echo "---> QtDesigner"
		cp -rfv `find tools/designer/src/lib -type f -name "*_p.h"` ${QTDIR}/include/QtDesigner/private >> priv_headers.log 2>&1
		cp -rfv `find tools/designer/src/lib -type f -name "*_pch.h"` ${QTDIR}/include/QtDesigner/private >> priv_headers.log 2>&1

		echo "---> QtGui"
		cp -rfv `find src/gui -type f -name "*_p.h"` ${QTDIR}/include/QtGui/private >> priv_headers.log 2>&1
		cp -rfv `find src/gui -type f -name "*_p.h"` ${QTDIR}/include/QtGui/private >> priv_headers.log 2>&1
	
		echo "---> QtHelp"
		cp -rfv `find tools/assistant -type f -name "*_p.h"` ${QTDIR}/include/QtHelp/private >> priv_headers.log 2>&1

		echo "---> QtMeeGoGraphicsSystemHelper"
		cp -rfv `find tools/qmeegographicssystemhelper -type f -name "*_p.h"` ${QTDIR}/include/QtMeeGoGraphicsSystemHelper/private >> priv_headers.log 2>&1

		echo "---> QtMultimedia"
		cp -rfv `find src/multimedia -type f -name "*_p.h"` ${QTDIR}/include/QtMultimedia/private >> priv_headers.log 2>&1

		echo "---> QtNetwork"
		cp -rfv `find src/network -type f -name "*_p.h"` ${QTDIR}/include/QtNetwork/private >> priv_headers.log 2>&1

		echo "---> QtOpenGl"
		cp -rfv `find src/opengl -type f -name "*_p.h"` ${QTDIR}/include/QtOpenGl/private >> priv_headers.log 2>&1

		echo "---> QtOpenVG"
		cp -rfv `find src/openvg -type f -name "*_p.h"` ${QTDIR}/include/QtOpenVG/private >> priv_headers.log 2>&1

		echo "---> QtScript"
		cp -rfv `find src/script -type f -name "*_p.h"` ${QTDIR}/include/QtScript/private >> priv_headers.log 2>&1

		echo "---> QtScriptTools"
		cp -rfv `find src/scripttools -type f -name "*_p.h"` ${QTDIR}/include/QtScriptTools/private >> priv_headers.log 2>&1

		echo "---> QtSql"
		cp -rfv `find src/sql -type f -name "*_p.h"` ${QTDIR}/include/QtSql/private >> priv_headers.log 2>&1

		echo "---> QtSvg"
		cp -rfv `find src/svg -type f -name "*_p.h"` ${QTDIR}/include/QtSvg/private >> priv_headers.log 2>&1

		echo "---> QtTest"
		cp -rfv `find src/testlib -type f -name "*_p.h"` ${QTDIR}/include/QtTest/private >> priv_headers.log 2>&1

		echo "---> QtUiTools"
		cp -rfv `find tools/designer/src/uitools -type f -name "*_p.h"` ${QTDIR}/include/QtUiTools/private >> priv_headers.log 2>&1

		echo "---> QtWebkit"
		cp -rfv `find src/3rdparty/webkit -type f -name "*_p.h"` ${QTDIR}/include/QtWebkit/private >> priv_headers.log 2>&1

		echo "---> QtXmlPatterns"
		cp -rfv `find src/xmlpatterns -type f -name "*_p.h"` ${QTDIR}/include/QtXmlPatterns/private >> priv_headers.log 2>&1

		echo "---> phonon"
		cp -rfv `find src/3rdparty/phonon/phonon -type f -name "*_p.h"` ${QTDIR}/include/phonon/private >> priv_headers.log 2>&1

		echo "--> Done install private headers"
		touch private_headers.marker
		popd > /dev/null
	fi
}
