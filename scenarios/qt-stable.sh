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
P_V=$P-stable
SRC_FILE=
URL_QT5=git://gitorious.org/qt/qt5.git
URL_QTACTIVEQT=git://gitorious.org/qt/qtactiveqt.git
URL_QTBASE=git://gitorious.org/qt/qtbase.git
URL_QTDECLARATIVE=git://gitorious.org/qt/qtdeclarative.git
URL_QTDOC=git://gitorious.org/qt/qtdoc.git
URL_QTGRAPHICALEFFECTS=git://gitorious.org/qt/qtgraphicaleffects.git
URL_QTIMAGEFOMATS=git://gitorious.org/qt/qtimageformats.git
URL_QTJSBACKEND=git://gitorious.org/qt/qtjsbackend.git
URL_QTMULTIMEDIA=git://gitorious.org/qt/qtmultimedia.git
URL_QTQUICK1=git://gitorious.org/qt/qtquick1.git
URL_QTSCRIPT=git://gitorious.org/qt/qtscript.git
URL_QTSVG=git://gitorious.org/qt/qtsvg.git
URL_QTTOOLS=git://gitorious.org/qt/qttools.git
URL_QTTRANSLATIONS=git://gitorious.org/qt/qttranslations.git
URL_QTWEBKIT=git://gitorious.org/qt/qtwebkit.git
URL_QTWEBKIT_EXAMPLES=git://gitorious.org/qt/qtwebkit-examples-and-demos.git
URL_QTXMLPATTERNS=git://gitorious.org/qt/qtxmlpatterns.git
URL_QTQUICKCONTROLS=git://gitorious.org/qt/qtquickcontrols.git

BRANCH="stable"
DEPENDS=(gperf icu fontconfig freetype libxml2 libxslt pcre perl ruby)

change_paths() {
	local _sql_include=
	local _sql_lib=
	[[ $STATIC_DEPS == no ]] && {
		_sql_include="$QTDIR/databases/firebird/include:$QTDIR/databases/mysql/include/mysql:$QTDIR/databases/pgsql/include:$QTDIR/databases/oci/include"
		_sql_lib="$QTDIR/databases/firebird/lib:$QTDIR/databases/mysql/lib:$QTDIR/databases/pgsql/lib:$QTDIR/databases/oci/lib"
	}
	export INCLUDE="$MINGWHOME/$HOST/include:$PREFIX/include:$PREFIX/include/libxml2:${_sql_include}"
	export LIB="$MINGWHOME/$HOST/lib:$PREFIX/lib:${_sql_lib}"
	OLD_PATH=$PATH
	export PATH=$BUILD_DIR/$P_V/gnuwin32/bin:$BUILD_DIR/$P_V/qtbase/bin:$BUILD_DIR/$P_V/qtbase/lib:$MINGW_PART_PATH:$WINDOWS_PART_PATH:$MSYS_PART_PATH
}

restore_paths() {
	unset INCLUDE
	unset LIB
	export PATH=$OLD_PATH
	unset OLD_PATH
}

src_download() {
	func_download $P_V "git" $URL_QT5 $BRANCH
	func_download $P_V/qtactiveqt "git" $URL_QTACTIVEQT $BRANCH
	func_download $P_V/qtbase "git" $URL_QTBASE $BRANCH
	func_download $P_V/qtdeclarative "git" $URL_QTDECLARATIVE $BRANCH
	func_download $P_V/qtdoc "git" $URL_QTDOC $BRANCH
	func_download $P_V/qtgraphicaleffects "git" $URL_QTGRAPHICALEFFECTS $BRANCH
	func_download $P_V/qtimageformats "git" $URL_QTIMAGEFOMATS $BRANCH
	func_download $P_V/qtjsbackend "git" $URL_QTJSBACKEND $BRANCH
	func_download $P_V/qtmultimedia "git" $URL_QTMULTIMEDIA $BRANCH
	func_download $P_V/qtquick1 "git" $URL_QTQUICK1 $BRANCH
	func_download $P_V/qtscript "git" $URL_QTSCRIPT $BRANCH
	func_download $P_V/qtsvg "git" $URL_QTSVG $BRANCH
	func_download $P_V/qttools "git" $URL_QTTOOLS $BRANCH
	func_download $P_V/qttranslations "git" $URL_QTTRANSLATIONS $BRANCH
	func_download $P_V/qtwebkit "git" $URL_QTWEBKIT $BRANCH
	func_download $P_V/qtwebkit-examples-and-demos "git" $URL_QTWEBKIT_EXAMPLES $BRANCH
	func_download $P_V/qtxmlpatterns "git" $URL_QTXMLPATTERNS $BRANCH
	func_download $P_V/qtquickcontrols "git" $URL_QTQUICKCONTROLS $BRANCH
}

src_unpack() {
	echo -n "--> Copy sources to ${BUILD_DIR}..."
	if [ -f $BUILD_DIR/${P_V}.marker ]
	then
		echo " copyied"
	else
		if [ -d $BUILD_DIR/${P_V} ]
		then
			rm -rf $BUILD_DIR/${P_V} || die "Cannot remove corrupted directory $BUILD_DIR/${P_V}"
		fi
		cp -rf $SRC_DIR/$P_V $BUILD_DIR || die "Copy failed"
		touch $BUILD_DIR/${P_V}.marker
		echo " done"
	fi
}

src_patch() {
	local _patches=(
		$P/5.0.x/qt-5.0.0-use-fbclient-instead-of-gds32.patch
		$P/5.0.x/qt-5.0.0-oracle-driver-prompt.patch
		$P/5.0.x/qt-5.0.0-fix-build-under-msys.patch
		$P/5.0.x/qt-5.0.0-win32-g++-mkspec-optimization.patch
		$P/5.0.x/qt-5.0.0-webkit-pkgconfig-link-windows.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@] \
		$BUILD_DIR
	
	pushd $BUILD_DIR/$P_V/qtbase/mkspecs/win32-g++ > /dev/null
		if [ -f qmake.conf.patched ]
		then
			rm -f qmake.conf
			cp -f qmake.conf.patched qmake.conf
		else
			cp -f qmake.conf qmake.conf.patched
		fi

		cat qmake.conf | sed 's|%OPTIMIZE_OPT%|'"$OPTIM"'|g' \
					| sed 's|%STATICFLAGS%|'"$STATIC_LD"'|g' > qmake.conf.tmp
		rm -f qmake.conf
		mv qmake.conf.tmp qmake.conf
	popd > /dev/null
	
	if [[ ! -d ${QTDIR}/databases && $STATIC_DEPS == no ]]
	then
		mkdir -p ${QTDIR}/databases
		cp -rf ${PATCH_DIR}/${P}/databases-${ARCHITECTURE}/* ${QTDIR}/databases/
	fi
}

src_configure() {

	if [ -f $BUILD_DIR/$P_V/configure.marker ]
	then
		echo "--> configured"
	else
		pushd $BUILD_DIR/$P_V > /dev/null
		echo -n "--> configure..."
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
		$PREFIX/perl/bin/perl configure \
			$_allconf \
			> ${LOG_DIR}/${P_V}_configure.log 2>&1 || die "Qt configure error"
	
		restore_paths
		echo " done"
		touch configure.marker
		popd > /dev/null
	fi
}

pkg_build() {
	change_paths
	[[ $USE_OPENGL_DESKTOP == no ]] && {
		# Workaround for
		# https://bugreports.qt-project.org/browse/QTBUG-28845
		pushd $BUILD_DIR/$P_V/qtbase/src/angle/src/libGLESv2 > /dev/null
		if [ -f workaround.marker ]
		then
			echo "--> Workaround applied"
		else
			echo -n "--> Applying workaround..."
			qmake libGLESv2.pro
			cat Makefile.Debug | grep fxc.exe | cmd > workaround.log 2>&1
			echo " done"
			touch workaround.marker
		fi
		popd > /dev/null
	} 
	
	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		$P_V \
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
		$P_V \
		"mingw32-make" \
		"$_allinstall" \
		"installing..." \
		"installed"

	install_docs

	# Workaround for build other components (qbs, qtcreator, etc)
	if [[ ! -f $BUILD_DIR/$P_V/qwindows.marker && $STATIC_DEPS == yes ]]
	then
		cp -f ${QTDIR}/plugins/platforms/libqwindows.a ${QTDIR}/lib/
		cp -f ${QTDIR}/plugins/platforms/libqwindowsd.a ${QTDIR}/lib/
		touch $BUILD_DIR/$P_V/qwindows.marker
	fi

	restore_paths
}

install_docs() {

	local _make_flags=(
		${MAKE_OPTS}
		docs
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		$P_V \
		"mingw32-make" \
		"$_allmake" \
		"building docs..." \
		"built-docs"

	_make_flags=(
		${MAKE_OPTS}
		install_qch_docs
	)
	_allmake="${_make_flags[@]}"
	func_make \
		$P_V \
		"mingw32-make" \
		"$_allmake" \
		"installing docs..." \
		"installed-docs"
}
