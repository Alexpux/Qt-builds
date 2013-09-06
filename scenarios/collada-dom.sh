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

P=collada-dom
P_V=${P}-${COLLADA_DOM_VERSION}
SRC_FILE=
URL=svn://svn.code.sf.net/p/collada-dom/code/trunk
DEPENDS=()

src_download() {
	func_download $P_V "svn" $URL

}

src_unpack() {
	echo "--> Empty unpack"
}

src_patch() {
	local _patches=(
		$P/collada-2.4.0-mingw-w64-fix.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
}

src_configure() {
	[[ ! -f $BUILD_DIR/$P_V/configure.marker ]] && {
		mkdir -p $BUILD_DIR/$P_V
		echo -n "--> configuring..."
		pushd $BUILD_DIR/$P_V > /dev/null
		local _rell=$( func_absolute_to_relative $BUILD_DIR/$P_V $UNPACK_DIR/$P_V )
		$PREFIX/bin/cmake \
			$_rell \
			-G 'MSYS Makefiles' \
			-DCMAKE_INSTALL_PREFIX=$PREFIX \
			-DCMAKE_BUILD_TYPE=Release \
			-DBOOST_ROOT=$PREFIX/boost-${BOOST_VERSION} \
			> $LOG_DIR/${P_V//\//_}-configure.log 2>&1 || die "Error configure $P_V"
		touch configure.marker
		popd > /dev/null
		echo " done"
	} || {
		echo "--> Already configured"
	}
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
}
