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

P=installer-framework
P_V=$P
SRC_FILE=
URL=git://gitorious.org/${P}/${P}.git

DEPENDS=(qt)

src_download() {
	if [ -d $SRC_DIR/$P_V ]
	then
		pushd $SRC_DIR/$P_V > /dev/null
			git clean -f > /dev/null
		popd > /dev/null
	fi
	func_download $P_V "git" $URL
}

src_unpack() {
	echo "--> Empty unpack"
}

src_patch() {
	local _patches=(
	)
	
	func_apply_patches \
		$P_V \
		_patches[@] \
		$SRC_DIR
}

src_configure() {
	mkdir -p $BUILD_DIR/${P_V}-${QTVER}

	if [ -f $BUILD_DIR/${P_V}-${QTVER}/configure.marker ]
	then
		echo "--> configured"
	else
		pushd $BUILD_DIR/${P_V}-${QTVER} > /dev/null
		echo -n "--> configure..."
		local _rel_path=$( func_absolute_to_relative $BUILD_DIR/${P_V}-${QTVER} $SRC_DIR/$P_V ) 
		${QTDIR}/bin/qmake.exe $_rel_path/installerfw.pro CONFIG+=release \
			> ${LOG_DIR}/${P_V}-${QTVER}-configure.log 2>&1 || die "QMAKE failed"
		echo " done"
		touch configure.marker
		popd > /dev/null
	fi
}

pkg_build() {
	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		${P_V}-${QTVER} \
		"mingw32-make" \
		"$_allmake" \
		"building..." \
		"built"
}

pkg_install() {
	local _install_flags=(
		INSTALL_ROOT=${QTDIR}
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		${P_V}-${QTVER} \
		"mingw32-make" \
		"$_allinstall" \
		"installing..." \
		"installed"
}