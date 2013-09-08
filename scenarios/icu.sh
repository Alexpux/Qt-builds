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

P=icu
P_V=${P}4c-${ICU_VERSION//./_}-src
EXT=".tgz"
SRC_FILE="${P_V}${EXT}"
URL=http://download.icu-project.org/files/icu4c/${ICU_VERSION}/${SRC_FILE}
DEPENDS=()

src_download() {
	func_download $P_V $EXT $URL
}

src_unpack() {
	func_uncompress $P_V $EXT
	
	pushd $UNPACK_DIR > /dev/null
	if ! [ -f $P_V/post-unpack.marker ]
		then
		echo -n "--> Move icu to $P_V..."
		mv -f $P $P_V
		echo "done"
	fi
	touch $P_V/post-unpack.marker
	popd > /dev/null	
}

src_patch() {
	local _patches=(
		$P/icu4c-4_9_1-crossbuild.patch
		$P/icu4c-4_9_1-mingw-w64-mkdir-compatibility.patch
		$P/icu-50.1-import-lib-ext.patch
		$P/icu-config.patch
		$P/icu-pkgconfig.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
}

src_configure() {
	pushd $UNPACK_DIR/$P_V/source > /dev/null
	if ! [ -f pre-configure.marker ]
	then
		echo -n "--> Execute before configure..."
		autoconf --force > execute.log 2>&1
		echo " done"
	fi
	touch pre-configure.marker
	popd > /dev/null
	
	local _conf_flags=(
		--prefix=${PREFIX}
		--build=${HOST}
		--host=${HOST}
		--target=${HOST}
		${LNKDEPS}
		--disable-rpath
		CFLAGS="\"${HOST_CFLAGS}\""
		LDFLAGS="\"${HOST_LDFLAGS}\""
		CPPFLAGS="\"${HOST_CPPFLAGS}\""
	)
	local _allconf="${_conf_flags[@]}"
	func_configure $P_V $P_V/source "$_allconf"
}

pkg_build() {
	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		${P_V} \
		"/bin/make" \
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
		${P_V} \
		"/bin/make" \
		"$_allinstall" \
		"installing..." \
		"installed"

	if ! [ -f $BUILD_DIR/$P_V/post-install.marker ]
	then
		echo -n "--> Execute after install..."
		for i in ${PREFIX}/lib/*.dll ; \
			do cp -f ${i} ${PREFIX}/bin/; done
		echo " done"
		touch $BUILD_DIR/$P_V/post-install.marker
	fi
}
