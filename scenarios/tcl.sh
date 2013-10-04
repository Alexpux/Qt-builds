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

P=tcl
P_V=${P}${TCL_VERSION}
EXT=".tar.gz"
SRC_FILE="${P_V}-src${EXT}"
URL=http://prdownloads.sourceforge.net/tcl/${SRC_FILE}
DEPENDS=()

src_download() {
	func_download $P_V $EXT $URL
}

src_unpack() {
	func_uncompress $P_V-src $EXT
}

src_patch() {
	local _patches=(
		$P/tcl-8.5.14-autopath.patch
		$P/tcl-8.5.14-conf.patch
		$P/tcl-8.5.14-hidden.patch
		$P/tcl-mingw-w64-compatibility.patch
		$P/tcl-8.6.1-mingwexcept.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
}

src_configure() {
	lndirs
	
	local _conf_flags=(
		--build=${HOST}
		--host=${HOST}
		--target=${HOST}
		--prefix=${PREFIX}
		--with-tcl=$PREFIX/lib
		--enable-shared
	)
	local _allconf="${_conf_flags[@]}"
	func_configure $P_V/win win "$_allconf" $BUILD_DIR/$P_V
}

pkg_build() {
	local _make_flags=(
		-j1
		TCL_LIBRARY=$LIBS_DIR/lib/tcl8.6
		all
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		${P_V}/win \
		"/bin/make" \
		"$_allmake" \
		"building..." \
		"built"
}

pkg_install() {

	local _install_flags=(
		TCL_LIBRARY=$LIBS_DIR/lib/tcl8.6
		install
	)

	local _allinstall="${_install_flags[@]}"
	func_make \
		${P_V}/win \
		"/bin/make" \
		"$_allinstall" \
		"installing..." \
		"installed"

	[[ ! -f $BUILD_DIR/$P_V/post-install.marker ]] && {
		ln -s $PREFIX/bin/tclsh86.exe $PREFIX/bin/tclsh.exe
		mv $PREFIX/lib/libtcl86.a $PREFIX/lib/libtcl86.dll.a
		mv $PREFIX/lib/libtclstub86.a $PREFIX/lib/libtclstub86.dll.a
		ln -s $PREFIX/lib/libtcl86.dll.a $PREFIX/lib/libtcl.dll.a
		ln -s $PREFIX/lib/tclConfig.sh $PREFIX/lib/tcl8.6/tclConfig.sh
		mkdir -p $PREFIX/include/tcl-private/{generic,win}
		find $UNPACK_DIR/$P_V/generic $UNPACK_DIR/$P_V/win -name \"*.h\" -exec cp -p '{}' $PREFIX/include/tcl-private/'{}' ';'

		touch $BUILD_DIR/$P_V/post-install.marker
	}
}
