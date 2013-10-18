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

P=tk
P_V=${P}${TK_VERSION}
PKG_TYPE=".tar.gz"
PKG_SRC_FILE="${P_V}-src${PKG_TYPE}"
PKG_URL=(
	"http://prdownloads.sourceforge.net/tcl/${PKG_SRC_FILE}"
)
PKG_DEPENDS=()

PKG_LNDIR=yes
PKG_SRC_SUBDIR=win

src_download() {
	func_download
}

src_unpack() {
	func_uncompress
}

src_patch() {
	local _patches=(
		$P/tk-8.6.1-mingwexcept.patch
		$P/tk-8.6.1-prevent-tclStubsPtr-segfault.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
}

src_configure() {
	local _conf_flags=(
		--build=${HOST}
		--host=${HOST}
		--target=${HOST}
		--prefix=${PREFIX}
		--with-tcl=$PREFIX/lib
		--enable-shared
	)
	local _allconf="${_conf_flags[@]}"
	func_configure "$_allconf"
	
	[[ ! -f $BUILD_DIR/$P_V/post-conf.marker ]] && {
		pushd $BUILD_DIR/$P_V > /dev/null
		sed -i -e 's,mingw-tcl,tcl,g' win/Makefile
		sed -i -e 's,/usr/include,$LIBS_DIR/include,g' win/Makefile
		sed -i -e 's,libtclstub86.a,libtclstub86.dll.a,g' win/Makefile
		sed -i -e 's,tcl8.5/libtclstub86,libtclstub86,g' win/Makefile
		sed -i -e 's,libtcl86.a,libtcl86.dll.a,g' win/Makefile
		sed -i -e 's,tcl8.6/libtcl86,libtcl86,g' win/Makefile
		popd > /dev/null

		touch $BUILD_DIR/$P_V/post-conf.marker
	}
}

pkg_build() {
	local _make_flags=(
		-j1
		TCL_LIBRARY=$PREFIX/lib/tk8.6
		all
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"building..." \
		"built"
}

pkg_install() {

	local _install_flags=(
		TK_LIBRARY=$PREFIX/lib/tk8.6
		install
	)

	local _allinstall="${_install_flags[@]}"
	func_make \
		"$_allinstall" \
		"installing..." \
		"installed"

	[[ ! -f $BUILD_DIR/$P_V/post-install.marker ]] && {
		ln -s $PREFIX/bin/wish86.exe $PREFIX/bin/wish.exe
		mv $PREFIX/lib/libtk86.a $PREFIX/lib/libtk86.dll.a
		mv $PREFIX/lib/libtkstub86.a $PREFIX/lib/libtkstub86.dll.a
		ln -s $PREFIX/lib/libtk86.dll.a $PREFIX/lib/libtk.dll.a
		ln -s $PREFIX/lib/tkConfig.sh $PREFIX/lib/tk8.6/tkConfig.sh
		mkdir -p $PREFIX/include/tk-private/{generic,win}
		find $UNPACK_DIR/$P_V/generic $UNPACK_DIR/$P_V/win -name \"*.h\" -exec cp -p '{}' $PREFIX/include/tcl-private/'{}' ';'

		touch $BUILD_DIR/$P_V/post-install.marker
	}
}
