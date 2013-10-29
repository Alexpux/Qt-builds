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

P=qt-creator
P_V=${P}-${QT_CREATOR_VERSION}-src
PKG_TYPE=".tar.gz"
PKG_SRC_FILE="${P_V}${PKG_TYPE}"
PKG_URL=(
	"http://download.qt-project.org/official_releases/qtcreator/3.0/${QT_CREATOR_VERSION}/${PKG_SRC_FILE}"
	# "http://download.qt-project.org/development_releases/qtcreator/3.0/${QT_CREATOR_VERSION}/${PKG_SRC_FILE}"
)
PKG_UNCOMPRESS_SKIP_ERRORS=yes
PKG_DEPENDS=(qt)
PKG_USE_QMAKE=yes
PKG_CONFIGURE=qtcreator.pro
PKG_MAKE=mingw32-make
PKG_LNDIR_DEST=${P_V}-${QTVER}-${QTDIR_PREFIX}

src_download() {
	func_download 
}

src_unpack() {
	func_uncompress
}

src_patch() {
	local _patches=(
	)

	func_apply_patches \
		_patches[@]
}

src_configure() {
	local _conf_flags=(
		CONFIG+=release
	)
	local _allconf="${_conf_flags[@]}"
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
	export INSTALL_ROOT=${QTDIR}
	local _install_flags=(
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		"$_allinstall" \
		"installing..." \
		"installed"

	# install_docs
	unset INSTALL_ROOT
}

install_docs() {

	local _make_flags=(
		${MAKE_OPTS}
		docs
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"building docs..." \
		"built-docs"

	_make_flags=(
		${MAKE_OPTS}
		install_docs
	)
	_allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"installing docs..." \
		"installed-docs"
}
