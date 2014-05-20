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

P=libxml2
P_V=${P}-${LIBXML2_VERSION}
PKG_TYPE=".tar.gz"
PKG_SRC_FILE="${P_V}${PKG_TYPE}"
PKG_URL=(
	"ftp://xmlsoft.org/libxslt/${PKG_SRC_FILE}"
)
PKG_DEPENDS=("icu" "readline" "xz-utils" "zlib")

src_download() {
	func_download
}

src_unpack() {
	func_uncompress
}

src_patch() {
	local _patches=(
		$P/libxml2-2.9.0-largefile.patch
		$P/libxml2-2.9.0-man_fixes.patch
		$P/libxml2-2.9.0-open.gz.patch
		$P/0004-detect-ws2tcpip.mingw.patch
		$P/0005-fix-char-cast-warning.mingw.patch
		$P/0006-fix-unused-var-warning.mingw.patch
		$P/0007-fix-stat-redefinition.mingw.patch
		$P/0008-include-winsock2.h-before-windows.h.mingw.patch
		$P/0009-use-wstat-appropriate-for-mingw-w64.mingw.patch
		$P/0010-mingw-w64-defines-lots-of-errnos.mingw.patch
		$P/0011-more-winsock-inclusion-order-fixes.mingw.patch
		$P/0012-socklen-is-signed-on-mingw-w64.mingw.patch
		$P/0013-fix-field-type-signedness.all.patch
		$P/0014-fix-prototype-warning.all.patch
		$P/0015-fix-unused-parameters-warning.all.patch
		$P/0016-WARNING-to-be-fixed.all.patch
		$P/0017-fix-const-warning.all.patch
		$P/0018-function-declaration-isnt-prototype.all.patch
		$P/0019-unused-flags.all.patch
		$P/0020-fix-size_t-format-specifier.all.patch
		$P/0023-fix-sitedir-detection.mingw.patch
		$P/0024-shrext-pyd.mingw.patch
		$P/0025-mingw-python-dont-remove-dot.patch
	)
	
	func_apply_patches \
		_patches[@]
}

src_configure() {
	[[ ! -f $UNPACK_DIR/$P_V/pre-configure.marker ]] && {
		pushd $UNPACK_DIR/$P_V > /dev/null
		echo -n "---> Execute before configure..."
		libtoolize --copy --force > execute.log 2>&1
		aclocal >> execute.log 2>&1
		automake --add-missing >> execute.log 2>&1
		autoconf >> execute.log 2>&1
		echo " done"
		touch pre-configure.marker
		popd > /dev/null
	}

	local _conf_flags=(
		--prefix=${PREFIX}
		--build=${HOST}
		--host=${HOST}
		--target=${HOST}
		${LNKDEPS}
		--with-modules
		--without-python
		--with-threads=win32
		CFLAGS="\"${HOST_CFLAGS}\""
		LDFLAGS="\"${HOST_LDFLAGS}\""
		CPPFLAGS="\"${HOST_CPPFLAGS}\""
	)
	local _allconf="${_conf_flags[@]}"
	export lt_cv_deplibs_check_method='pass_all'
	func_configure "$_allconf"
}

pkg_build() {
	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"building..." \
		"built"
}

pkg_install() {
	local _install_flags=(
		${MAKE_OPTS}
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		"$_allinstall" \
		"installing..." \
		"installed"
}
