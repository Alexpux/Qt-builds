
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

P=boost
P_V=${P}_${BOOST_VERSION//./_}
PKG_TYPE=".tar.bz2"
PKG_SRC_FILE="${P_V}${PKG_TYPE}"
PKG_URL=(
	"http://download.sourceforge.net/${P}/${PKG_SRC_FILE}"
)
PKG_DEPENDS=()

PKG_LNDIR=yes
PKG_CONFIGURE=bootstrap.sh
PKG_MAKE="./b2"

src_download() {
	func_download
}

src_unpack() {
	func_uncompress
}

src_patch() {
	local _patches=(
		$P/boost-1.48.0-add-bjam-man-page.patch
		$P/boost-1.50.0-fix-non-utf8-files.patch
		$P/boost-1.50.0-pool.patch
		$P/boost-1.54.0-bind-static_assert.patch
		$P/boost-1.54.0-bootstrap.patch
		$P/boost-1.54.0-concept-unused_typedef.patch
		$P/boost-1.55.0-log_fix_dump_avx2.patch
		$P/boost-mingw.patch
		$P/using-mingw-w64-python.patch
	)

	func_apply_patches \
		_patches[@]
}

src_configure() {
	local _conf_flags=(
		--with-icu=$PREFIX
	)
	local _allconf="${_conf_flags[@]}"
	func_configure "$_allconf"
}

pkg_build() {
	local _bvar="variant=release threading=single,multi threadapi=win32 \
		link=shared,static debug-symbols=on pch=off link=shared toolset=gcc"
	local _bflag="-d2 --layout=tagged address-model=$( [[ $ARCHITECTURE == i686 ]] && echo 32 || echo 64 ) \
		${_bvar} --without-mpi --without-python "

	local _make_flags=(
		${MAKE_OPTS}
		${_bflag}
		--prefix=${PREFIX}
		-sHAVE_ICU=1
		-sICU_PATH=${PREFIX}
		-sICU_LINK="\"-L${PREFIX}/lib -licuuc -licuin -licudt\""
		-sICONV_PATH=${PREFIX}
		stage
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"building..." \
		"built"
}

pkg_install() {
	local _bvar="variant=release threading=single,multi threadapi=win32 \
		link=shared,static debug-symbols=on pch=off link=shared toolset=gcc"
	local _bflag="-d2 --layout=tagged address-model=$( [[ $ARCHITECTURE == i686 ]] && echo 32 || echo 64 ) \
		${_bvar} --without-mpi --without-python "

	local _install_flags=(
		${MAKE_OPTS}
		${_bflag}
		--prefix=${PREFIX}
		-sHAVE_ICU=1
		-sICU_PATH=${PREFIX}
		-sICU_LINK="\"-L${PREFIX}/lib -licuuc -licuin -licudt\""
		-sICONV_PATH=${PREFIX}
		-sICONV_LINK="\"-L${PREFIX}/lib -liconv\""
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		"$_allinstall" \
		"installing..." \
		"installed"

	[[ ! -f $BUILD_DIR/${P_V}/post-install.marker ]] && {
		local binary=
		pushd ${PREFIX}/lib > /dev/null
		find * -type f -name 'libboost*.dll' -print0 | \
		while read -d $'\0' binary
		do
			mv -f $binary ${PREFIX}/bin/$binary
		done
		popd > /dev/null
		touch $BUILD_DIR/${P_V}/post-install.marker
	}
}
