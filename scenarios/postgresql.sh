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

P=postgresql
P_V=${P}-${POSTGRESQL_VERSION}
PKG_EXT=".tar.bz2"
PKG_SRC_FILE="${P_V}${PKG_EXT}"
PKG_URL=http://ftp.postgresql.org/pub/source/v${POSTGRESQL_VERSION}/${PKG_SRC_FILE}
PKG_DEPENDS=()

src_download() {
	func_download $P_V $PKG_EXT $PKG_URL
}

src_unpack() {
	func_uncompress $P_V $PKG_EXT
}

src_patch() {
	local _patches=(
		$P/postgresql-9.2.4-plperl-mingw.patch
		$P/postgresql-9.2.4-plpython-mingw.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
}

src_configure() {
	local _conf_flags=(
		--prefix=${PREFIX}
		--build=${HOST}
		--host=${HOST}
		--target=${HOST}
		--with-openssl
		--with-libxml
		--with-libxslt
		--with-perl
		--with-python
		CFLAGS="\"${HOST_CFLAGS}\""
		LDFLAGS="\"${HOST_LDFLAGS}\""
		CPPFLAGS="\"${HOST_CPPFLAGS}\""
	)
	local _allconf="${_conf_flags[@]}"
	func_configure "$_allconf"
	
	pushd $BUILD_DIR/$P_V > /dev/null
		[[ ! -f defs.marker ]] && {
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/compatlib/blibecpg_compatdll.def src/interfaces/ecpg/compatlib/blibecpg_compatdll.def
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/compatlib/libecpg_compatddll.def src/interfaces/ecpg/compatlib/libecpg_compatddll.def
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/compatlib/libecpg_compatdll.def src/interfaces/ecpg/compatlib/libecpg_compatdll.def
			
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/ecpglib/blibecpgdll.def src/interfaces/ecpg/ecpglib/blibecpgdll.def
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/ecpglib/libecpgddll.def src/interfaces/ecpg/ecpglib/libecpgddll.def
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/ecpglib/libecpgdll.def src/interfaces/ecpg/ecpglib/libecpgdll.def
			
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/pgtypeslib/blibpgtypesdll.def src/interfaces/ecpg/pgtypeslib/blibpgtypesdll.def
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/pgtypeslib/libpgtypesddll.def src/interfaces/ecpg/pgtypeslib/libpgtypesddll.def
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/ecpg/pgtypeslib/libpgtypesdll.def src/interfaces/ecpg/pgtypeslib/libpgtypesdll.def
			
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/libpq/blibpqdll.def src/interfaces/libpq/blibpqdll.def
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/libpq/libpqddll.def src/interfaces/libpq/libpqddll.def
			cp -rf $UNPACK_DIR/$P_V/src/interfaces/libpq/libpqdll.def src/interfaces/libpq/libpqdll.def
			
			touch defs.marker
		}
	popd > /dev/null
}

pkg_build() {
	local _make_flags=(
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
		${MAKE_OPTS}
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		"$_allinstall" \
		"installing..." \
		"installed"

	pushd $BUILD_DIR/$P_V > /dev/null
		[[ ! -f postinstall.marker ]] && {
			cp -f $PREFIX/lib/*.dll $PREFIX/bin/
			touch postinstall.marker
		}
	popd > /dev/null	
}
