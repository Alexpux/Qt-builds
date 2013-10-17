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
PKG_EXT=".tar.gz"
PKG_SRC_FILE="${P_V}${PKG_EXT}"
PKG_URL=http://releases.qt-project.org/qt5/${QT_VERSION}/single/$PKG_SRC_FILE
PKG_MIRROR=http://download.qt-project.org/official_releases/qt/5.0/${QT_VERSION}/single/$PKG_SRC_FILE
PKG_DEPENDS=(gperf icu fontconfig freetype libxml2 libxslt pcre perl ruby)

PKG_LNDIR=yes
PKG_LNDIR_SRC=$P_V
PKG_LNDIR_DEST=$P-$QT_VERSION-$QTDIR_PREFIX
PKG_CONFIGURE=configure.bat
PKG_MAKE=mingw32-make

change_paths() {
	local _sql_include=
	local _sql_lib=
	[[ $STATIC_DEPS == no ]] && {
		_sql_include="$QTDIR/databases/firebird/include:$QTDIR/databases/mysql/include/mysql:$QTDIR/databases/pgsql/include:$QTDIR/databases/oci/include"
		_sql_lib="$QTDIR/databases/firebird/lib:$QTDIR/databases/mysql/lib:$QTDIR/databases/pgsql/lib:$QTDIR/databases/oci/lib"
	}
	export INCLUDE="$MINGWHOME/$HOST/include:$PREFIX/include:$PREFIX/include/libxml2:${_sql_include}"
	export LIB="$MINGWHOME/$HOST/lib:$PREFIX/lib:${_sql_lib}"
	export CPATH="$MINGWHOME/$HOST/include:$PREFIX/include:$PREFIX/include/libxml2:${_sql_include}"
	export LIBRARY_PATH="$MINGWHOME/$HOST/lib:$PREFIX/lib:${_sql_lib}"
	OLD_PATH=$PATH
	export PATH=$BUILD_DIR/$P-$QT_VERSION-$QTDIR_PREFIX/qtbase/bin:$MINGW_PART_PATH:$MSYS_PART_PATH:$WINDOWS_PART_PATH
	# $BUILD_DIR/$P-$QT_VERSION-$QTDIR_PREFIX/gnuwin32/bin:
}

restore_paths() {
	unset INCLUDE
	unset LIB
	unset CPATH
	unset LIBRARY_PATH
	export PATH=$OLD_PATH
	unset OLD_PATH
}

src_download() {
	func_download $P_V $PKG_EXT $PKG_URL
}

src_unpack() {
	func_uncompress $P_V $PKG_EXT
}

src_patch() {
	local _patches=(
		$P/5.0.x/qt-5.0.0-use-fbclient-instead-of-gds32.patch
		$P/5.0.x/qt-5.0.0-oracle-driver-prompt.patch
		$P/5.0.x/qt-5.0.0-fix-build-under-msys.patch
		$P/5.0.x/qt-5.0.0-win32-g++-mkspec-optimization.patch
		$P/5.0.x/qt-5.0.0-webkit-pkgconfig-link-windows.patch
		$P/5.0.x/qt-5.0.1-fix-angle-static-build.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
		
	touch $UNPACK_DIR/$P_V/qtbase/.gitignore
}

src_configure() {
	[[ ! -d ${QTDIR}/databases && $STATIC_DEPS == no ]] && {
		mkdir -p ${QTDIR}/databases
		echo "---> Sync database folder... "
		rsync -av ${PATCH_DIR}/${P}/databases-${ARCHITECTURE}/ ${QTDIR}/databases/ > /dev/null
		echo "done"
	}

	pushd $BUILD_DIR/$P-$QT_VERSION-$QTDIR_PREFIX/qtbase/mkspecs/win32-g++ > /dev/null
		[[ -f qmake.conf.patched ]] && {
			rm -f qmake.conf
			cp -f qmake.conf.patched qmake.conf
		} || {
			cp -f qmake.conf qmake.conf.patched
		}

		cat qmake.conf | sed 's|%OPTIMIZE_OPT%|'"$OPTIM"'|g' \
					| sed 's|%STATICFLAGS%|'"$STATIC_LD"'|g' > qmake.conf.tmp
		rm -f qmake.conf
		mv qmake.conf.tmp qmake.conf
	popd > /dev/null

	local _opengl
	[[ $USE_OPENGL_DESKTOP == yes ]] && {
		_opengl="-opengl desktop"
	} || {
		_opengl="-angle"
	}

	change_paths
	local _mode=shared
	[[ $STATIC_DEPS == yes ]] && {
		_mode=static
	}

	local _conf_flags=(
		-prefix $QTDIR_WIN
		-opensource
		-$_mode
		-confirm-license
		-debug-and-release
		$( [[ $STATIC_DEPS == no ]] \
			&& echo "-plugin-sql-ibase \
					 -plugin-sql-mysql \
					 -plugin-sql-psql \
					 -plugin-sql-oci \
					 -plugin-sql-odbc \
					 -no-iconv \
					 -icu \
					 -system-pcre \
					 -system-zlib" \
			|| echo "-no-icu \
					 -no-iconv \
					 -qt-sql-sqlite \
					 -qt-zlib \
					 -qt-pcre" \
		)
		-fontconfig
		-openssl
		-no-dbus
		$_opengl
		-platform win32-g++
		-nomake tests
		-nomake examples
	)
	local _allconf="${_conf_flags[@]}"
	func_configure "$_allconf"
}

pkg_build() {
	change_paths
	[[ $USE_OPENGL_DESKTOP == no ]] && {
		# Workaround for
		# https://bugreports.qt-project.org/browse/QTBUG-28845
		pushd $BUILD_DIR/$P-$QT_VERSION-$QTDIR_PREFIX/qtbase/src/angle/src/libGLESv2 > /dev/null
		[[ -f workaround.marker ]] && {
			echo "---> Workaround applied"
		} || {
			echo -n "---> Applying workaround..."
			qmake libGLESv2.pro
			cat Makefile.Debug | grep fxc.exe | cmd > workaround.log 2>&1
			echo " done"
			touch workaround.marker
		}
		popd > /dev/null
	} 
	
	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
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
		"$_allinstall" \
		"installing..." \
		"installed"

	install_docs

	# Workaround for build other components (qbs, qtcreator, etc)
	[[ ! -f $BUILD_DIR/$P-$QT_VERSION-$QTDIR_PREFIX/qwindows.marker && $STATIC_DEPS == yes ]] && {
		cp -f ${QTDIR}/plugins/platforms/libqwindows.a ${QTDIR}/lib/
		cp -f ${QTDIR}/plugins/platforms/libqwindowsd.a ${QTDIR}/lib/
		touch $BUILD_DIR/$P-$QT_VERSION-$QTDIR_PREFIX/qwindows.marker
	}

	restore_paths
}

install_docs() {

	local _make_flags=(
		${MAKE_OPTS}
		docs
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"building docs..." \
		"built-docs"

	_make_flags=(
		${MAKE_OPTS}
		install_qch_docs
	)
	_allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"installing docs..." \
		"installed-docs"
}
