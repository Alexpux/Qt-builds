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

P=openssl
P_V=${P}-${OPENSSL_VERSION}
PKG_TYPE=".tar.gz"
PKG_SRC_FILE="${P_V}${PKG_TYPE}"
PKG_URL=(
	"http://www.openssl.org/source/${PKG_SRC_FILE}"
)
PKG_LNDIR=yes
PKG_CONFIGURE=Configure

src_download() {
	func_download
}

src_unpack() {
	func_uncompress
}

src_patch() {
	local _patches=(
		$P/${P}-1.0.0a-ldflags.patch
		$P/${P}-1.0.0d-windres.patch
		$P/${P}-1.0.0h-pkg-config.patch
		$P/${P}-1.0.1-parallel-build.patch
		$P/${P}-1.0.1-x32.patch
		$P/${P}-0.9.6-x509.patch
		$P/${P}-1.0.1f-manfix.patch
	)
	
	func_apply_patches \
		_patches[@]
}

src_configure() {
	[[ $ARCHITECTURE == x86_64 ]] &&
	{
		TOOLSET=mingw64
	} || {
		TOOLSET=mingw
	}	

	local _mode=
	[[ $STATIC_DEPS == no ]] && {
		_mode=shared
	}

	unset APPS
	unset SCRIPTS
	unset CROSS_COMPILE

	local _conf_flags=(
		--prefix=${PREFIX}
		$_mode
		threads
		zlib
		enable-camellia
		enable-idea
		enable-mdc2
		enable-tlsext
		enable-rfc3779
		${TOOLSET}
	)
	local _allconf="${_conf_flags[@]}"
	func_configure "$_allconf"

	unset TOOLSET
}

pkg_build() {
	local _make_flags=(
		ZLIB_INCLUDE=-"I${PREFIX}/include"
		depend
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
}
