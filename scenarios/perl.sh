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

P="perl"
P_V=${P}-${PERL_VERSION}
PKG_EXT=".tar.gz"
PKG_SRC_FILE="${P_V}${PKG_EXT}"
PKG_URL=http://www.cpan.org/src/5.0/${PKG_SRC_FILE}
PKG_DEPENDS=(dmake)

change_paths() {
	OLD_PATH=$PATH
	export PATH=$MINGW_PART_PATH:$WINDOWS_PART_PATH:$MSYS_PART_PATH
}

restore_paths() {
	export PATH=$OLD_PATH
	unset OLD_PATH
}

src_download() {
	func_download $P_V $PKG_EXT $PKG_URL
}

src_unpack() {
	func_uncompress $P_V $PKG_EXT
}

src_patch() {
	local _patches=(
		$P/perl-5.18.0-add-missing-mingw-libs.patch
		$P/perl-variables.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
}

src_configure() {
	lndirs

	[[ -f $BUILD_DIR/$P_V/win32/configure.marker ]] && {
		echo "---> configured"
	} || {
		pushd $BUILD_DIR/$P_V/win32 > /dev/null
		echo -n "---> configure..."
		
		local DRV=`expr substr $MINGW_PERL_PREFIX_W 1 2`
		local NOTDRV=${PREFIX_WIN#$DRV}
		NOTDRV=$(echo $NOTDRV | sed 's|/|\\\\|g')
		local MINGWHOME_WIN_P=$(echo $MINGWHOME_WIN | sed 's|/|\\\\|g')

		local COMMA=
		local EXTRA=$MINGWHOME_WIN/$TARGET/lib
		[[ $ARCHITECTURE == i686 ]] && {
			COMMA=""	
		} || {
			COMMA="#"
		}
		EXTRA=$(echo $EXTRA | sed 's|/|\\\\|g')
		
		cat makefile.mk | sed 's|%DRV%|'"$DRV"'|g' \
			| sed -e 's|%NODRV%|'"$NOTDRV"'|g' \
			| sed -e 's|%COMW64%|'"$COMMA"'|g' \
			| sed -e 's|%MINGWHOME%|'"$MINGWHOME_WIN_P"'|g' \
			| sed -e 's|%THIRDPARTY_LIBS%|'"$EXTRA"'|g' > makefile.tmp

		rm -f makefile.mk
		mv makefile.tmp makefile.mk
		echo " done"
		touch configure.marker
		popd > /dev/null
	}
}

pkg_build() {

	[[ -f $BUILD_DIR/$P_V/win32/make.marker ]] && {
		echo "---> Builded"
	} || {
		pushd $BUILD_DIR/$P_V/win32 > /dev/null
		echo "---> Building..."
		change_paths
		$PREFIX_WIN/bin/dmake || die "Error building PERL"
		restore_paths
		echo " done"
		touch make.marker
		popd > /dev/null
	}
}

pkg_install() {

	[[ -f $BUILD_DIR/$P_V/win32/install.marker ]] && {
		echo "---> Installed"
	} || {
		pushd $BUILD_DIR/$P_V/win32 > /dev/null
		echo "---> Installing..."
		change_paths
		$PREFIX_WIN/bin/dmake install || die "Error installing PERL"
		restore_paths
		echo " done"
		touch install.marker
		popd > /dev/null
	}
}
