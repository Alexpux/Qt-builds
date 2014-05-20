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
		$P/002-fix-forbidden-colon-in-paths.mingw.patch
		$P/003-fix-redefinition.mingw.patch
		$P/004-use-system-zlib.mingw.patch
		$P/005-no-xc.mingw.patch
		$P/006-proper-implib-name.mingw.patch
		$P/007-install.mingw.patch
		$P/008-tcl-8.5.14-hidden.patch
		$P/009-fix-using-gnu-print.patch
	)
	
	func_apply_patches \
		_patches[@]
	
	[[ ! -f $UNPACK_DIR/$P_V/win/post-patch.marker ]] && {
		pushd $UNPACK_DIR/$P_V/win > /dev/null
		echo -n "---> Executing..."
		autoreconf -fi
		echo " done"
		touch post-patch.marker
		popd > /dev/null
	}
}

src_configure() {
	local _conf_flags=(
		--build=${HOST}
		--host=${HOST}
		--target=${HOST}
		--prefix=${PREFIX}
		$( [[ $ARCHITECTURE == x86_64 ]] \
			&& echo "--enable-64bit"
		)
		--enable-threads
		--enable-shared
	)
	local _allconf="${_conf_flags[@]}"
	func_configure "$_allconf"
}

pkg_build() {
	local _make_flags=(
		-j1
		all
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"building..." \
		"built"
	
	[[ ! -f $BUILD_DIR/$P_V/post-make.marker ]] && {
		pushd $BUILD_DIR/$P_V > /dev/null
		echo -n "---> Executing..."
		cp tclsh86.exe tclsh.exe
		echo " done"
		touch post-make.marker
		popd > /dev/null
	}
}

pkg_install() {

	local _install_flags=(
		install
	)

	local _allinstall="${_install_flags[@]}"
	func_make \
		"$_allinstall" \
		"installing..." \
		"installed"

	[[ ! -f $BUILD_DIR/$P_V/post-install.marker ]] && {
		ln -s $PREFIX/bin/tclsh86.exe $PREFIX/bin/tclsh.exe
		
		local _libver=${TCL_VERSION%.*}
		_libver=${_libver//./}

		sed \
			-e "s|^\(TCL_BUILD_LIB_SPEC\)='.*|\1='-Wl,${PREFIX}/lib/libtcl${_libver}.dll.a'|" \
			-e "s|^\(TCL_SRC_DIR\)='.*'|\1='${PREFIX}/include/tcl${TCL_VERSION%.*}/tcl-private'|" \
			-e "s|^\(TCL_BUILD_STUB_LIB_SPEC\)='.*|\1='-Wl,${PREFIX}/lib/libtclstub${_libver}.a'|" \
			-e "s|^\(TCL_BUILD_STUB_LIB_PATH\)='.*|\1='${PREFIX}/lib'|" \
			-e "s|^\(TCL_STUB_LIB_SPEC\)='.*|\1='-L${PREFIX}/lib -ltclstub${_libver}'|" \
			-e "s|^\(TCL_INCLUDE_SPEC\)='.*|\1='-I${PREFIX}/include/tcl${TCL_VERSION%.*}'|" \
			-i "${MINGW_PREFIX}/lib/tclConfig.sh"

		sed \
			-e "s|^\(tdbc_BUILD_STUB_LIB_SPEC\)='.*|\1='-L${PREFIX}/lib/tdbc1.0.0 -ltdbcstub100'|" \
			-e "s|^\(TDBC_BUILD_STUB_LIB_SPEC\)='.*|\1='-L${PREFIX}/lib/tdbc1.0.0 -ltdbcstub100'|" \
			-e "s|^\(tdbc_BUILD_STUB_LIB_PATH\)='.*|\1='${PREFIX}/lib/tdbc1.0.0/libtdbcstub100.a'|" \
			-e "s|^\(TDBC_BUILD_STUB_LIB_PATH\)='.*|\1='${PREFIX}/lib/tdbc1.0.0/libtdbcstub100.a'|" \
			-e "s|^\(tdbc_INCLUDE_SPEC\)='.*|\1='${PREFIX}/lib/tdbc1.0.0/libtdbcstub100.a'|" \
			-e "s|^\(tdbc_INCLUDE_SPEC\)='.*|\1='${PREFIX}/lib/tdbc1.0.0/libtdbcstub100.a'|" \
			-i "${PREFIX}/lib/tdbc1.0.0/tdbcConfig.sh"

		sed \
			-e "s|^\(itcl_BUILD_LIB_SPEC\)='.*|\1='-L${PREFIX}/lib/itcl4.0.0 -litcl400'|" \
			-e "s|^\(ITCL_BUILD_LIB_SPEC\)='.*|\1='-L${PREFIX}/lib/itcl4.0.0 -litcl400'|" \
			-e "s|^\(itcl_BUILD_STUB_LIB_SPEC\)='.*|\1='-L${PREFIX}/lib/itcl4.0.0 -litclstub400'|" \
			-e "s|^\(ITCL_BUILD_STUB_LIB_SPEC\)='.*|\1='-L${PREFIX}/lib/itcl4.0.0 -litclstub400'|" \
			-e "s|^\(itcl_BUILD_STUB_LIB_PATH\)='.*|\1='${PREFIX}/lib/itcl4.0.0/libitclstub400.a'|" \
			-e "s|^\(ITCL_BUILD_STUB_LIB_PATH\)='.*|\1='${PREFIX}/lib/itcl4.0.0/libitclstub400.a'|" \
			-i "${PREFIX}/lib/itcl4.0.0/itclConfig.sh"

		ln -s "${PREFIX}/lib/libtcl86.dll.a" "${PREFIX}/lib/libtcl.dll.a"
		ln -s "${PREFIX}/lib/tclConfig.sh" "${PREFIX}/lib/tcl${TCL_VERSION%.*.*}/tclConfig.sh"

		# Install private headers
		mkdir -p "${PREFIX}/include/tcl${TCL_VERSION%.*}/tcl-private/"{generic,win}
		find $UNPACK_DIR/$P_V/generic $UNPACK_DIR/$P_V/win  -name "*.h" -exec cp -p '{}' "${PREFIX}"/include/tcl${TCL_VERSION%.*}/tcl-private/'{}' ';'
		( cd "${PREFIX}/include"
			for i in *.h ; do
				cp -f $i ${PREFIX}/include/tcl${TCL_VERSION%.*}/tcl-private/generic/
			done
		)
		chmod a-x "${PREFIX}/lib/tcl${TCL_VERSION%.*}/encoding/"*.enc
		chmod a-x "${PREFIX}/lib/"*/pkgIndex.tcl

		cp -rf ${PREFIX}/man ${pkgdir}${PREFIX}/share/
		rm -rf ${PREFIX}/man
		install -Dm644 $UNPACK_DIR/$P_V/win/tcl.m4 ${PREFIX}/share/aclocal/tcl${TCL_VERSION%.*}.m4

		touch $BUILD_DIR/$P_V/post-install.marker
	}
}
