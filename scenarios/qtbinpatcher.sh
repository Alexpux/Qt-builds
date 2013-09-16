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

P=qtbinpatcher
P_V=${P}-1.1.0
EXT=
SRC_FILE=
URL=

src_download() {
	echo "---> Local sources"
}

src_unpack() {
	[[ -f ${BUILD_DIR}/${P}-${QTVER}-${QTDIR_PREFIX}/$P_V.marker ]] && {
		echo "---> Sources copied"
	} || {
		echo -n "---> Copy sources..."
		mkdir -p ${BUILD_DIR}/$P-${QTVER}-${QTDIR_PREFIX}
		lndir ${PROG_DIR}/$P ${BUILD_DIR}/$P-${QTVER}-${QTDIR_PREFIX} || die "Error copy $P to $BUILD_DIR"
		touch ${BUILD_DIR}/$P-${QTVER}-${QTDIR_PREFIX}/${P_V}.marker
		echo " done"
	}
}

src_patch() {
	echo "---> No patches needed"
}

src_configure() {
	echo "---> Don't need configure"
}

pkg_build() {
	local _make_flags=(
		"-f Makefile.win.msys"
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		${P}-${QTVER}-${QTDIR_PREFIX} \
		"/bin/make" \
		"$_allmake" \
		"building..." \
		"built"
}

pkg_install() {
	[[ ! -f $BUILD_DIR/$P-${QTVER}-${QTDIR_PREFIX}/install-${QTVER}.marker ]] && {
		cp -f $BUILD_DIR/$P-${QTVER}-${QTDIR_PREFIX}/out/${P}.exe ${QTDIR}/ || die "Error copying ${P}.exe"
		touch $BUILD_DIR/$P-${QTVER}-${QTDIR_PREFIX}/install-${QTVER}.marker
	}
}
