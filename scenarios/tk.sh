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
		$P/002-implib-name.mingw.patch
		$P/003-fix-forbidden-colon-in-paths.mingw.patch
		$P/004-install-man.mingw.patch
		$P/005-fix-redefinition.mingw.patch
		$P/006-prevent-tclStubsPtr-segfault.patch
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
		--with-tcl=$PREFIX/lib
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
		ln -s $PREFIX/bin/wish86.exe $PREFIX/bin/wish.exe
		ln -s "${PREFIX}/lib/libtk86.dll.a" "${PREFIX}/lib/libtk.dll.a"
		mkdir -p "${PREFIX}/include/tk${TK_VERSION%.*}/tk-private/"{generic/ttk,win}
		find $UNPACK_DIR/$P_V/generic $UNPACK_DIR/$P_V/win -name "*.h" -exec cp -p '{}' "${PREFIX}"/include/tk${pkgver%.*}/tk-private/'{}' ';'
		( cd "${PREFIX}/include"
			for i in *.h ; do
				cp -f $i ${PREFIX}/include/tk${pkgver%.*}/tk-private/generic/
			done
		)
		chmod a-x "${PREFIX}/lib/"*/pkgIndex.tcl
  
		local _libver=${TK_VERSION%.*}
		_libver=${_libver//./}
		sed \
			-e "s|^\(TK_BUILD_LIB_SPEC\)='.*|\1='-Wl,${PREFIX}/lib/libtk${_libver}.dll.a'|" \
			-e "s|^\(TK_SRC_DIR\)='.*'|\1='${PREFIX}/include/tk${TK_VERSION%.*}/tk-private'|" \
			-e "s|^\(TK_BUILD_STUB_LIB_SPEC\)='.*|\1='-Wl,${PREFIX}/lib/libtkstub${_libver}.a'|" \
			-e "s|^\(TK_BUILD_STUB_LIB_PATH\)='.*|\1='${PREFIX}/lib/libtkstub${_libver}.a'|" \
			-e "s|^\(TK_STUB_LIB_SPEC\)='.*|\1='-L${PREFIX}/lib -ltkstub${_libver}'|" \
			-i ${PREFIX}/lib/tkConfig.sh

		# Add missing entry to tkConfig.sh
		echo "# String to pass to the compiler so that an extension can" >> ${PREFIX}/lib/tkConfig.sh
		echo "# find installed Tcl headers." >> ${PREFIX}/lib/tkConfig.sh
		echo "TK_INCLUDE_SPEC='-I${PREFIX}/include/tk${TK_VERSION%.*}'" >> ${PREFIX}/lib/tkConfig.sh

		rm "${PREFIX}/lib/tk${TK_VERSION%.*}/tkAppInit.c"

		touch $BUILD_DIR/$P_V/post-install.marker
	}
}
