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

P=Python
P_V=${P}-${PYTHON2_VERSION}
EXT=".tar.bz2"
SRC_FILE="${P_V}${EXT}"
URL=http://www.python.org/ftp/python/${PYTHON2_VERSION}/$SRC_FILE
DEPENDS=("expat" "libffi" "zlib")

src_download() {
	func_download $P_V $EXT $URL
}

src_unpack() {
	func_uncompress $P_V $EXT
}

src_patch() {
	local _patches=(
		$P/${PYTHON2_VERSION}/0005-MINGW.patch
		$P/${PYTHON2_VERSION}/0006-mingw-removal-of-libffi-patch.patch
		$P/${PYTHON2_VERSION}/0007-mingw-system-libffi.patch
		$P/${PYTHON2_VERSION}/0010-mingw-osdefs-DELIM.patch	
		$P/${PYTHON2_VERSION}/0015-mingw-use-posix-getpath.patch
		$P/${PYTHON2_VERSION}/0020-mingw-w64-test-for-REPARSE_DATA_BUFFER.patch
		$P/${PYTHON2_VERSION}/0025-mingw-regen-with-stddef-instead.patch
		$P/${PYTHON2_VERSION}/0030-mingw-add-libraries-for-_msi.patch
		$P/${PYTHON2_VERSION}/0035-MSYS-add-MSYSVPATH-AC_ARG.patch
		$P/${PYTHON2_VERSION}/0040-mingw-cygwinccompiler-use-CC-envvars-and-ld-from-print-prog-name.patch
		$P/${PYTHON2_VERSION}/0045-cross-darwin.patch
		$P/${PYTHON2_VERSION}/0050-mingw-sysconfig-like-posix.patch
		$P/${PYTHON2_VERSION}/0055-mingw-pdcurses_ISPAD.patch
		$P/${PYTHON2_VERSION}/0060-mingw-static-tcltk.patch
		$P/${PYTHON2_VERSION}/0065-mingw-x86_64-size_t-format-specifier-pid_t.patch
		$P/${PYTHON2_VERSION}/0070-python-disable-dbm.patch
		$P/${PYTHON2_VERSION}/0075-add-python-config-sh.patch
		$P/${PYTHON2_VERSION}/0080-mingw-nt-threads-vs-pthreads.patch
		$P/${PYTHON2_VERSION}/0085-cross-dont-add-multiarch-paths-if.patch
		$P/${PYTHON2_VERSION}/0090-mingw-reorder-bininstall-ln-symlink-creation.patch
		$P/${PYTHON2_VERSION}/0095-mingw-use-backslashes-in-compileall-py.patch
		$P/${PYTHON2_VERSION}/0100-mingw-distutils-MSYS-convert_path-fix-and-root-hack.patch
		$P/${PYTHON2_VERSION}/0105-mingw-MSYS-no-usr-lib-or-usr-include.patch
		$P/${PYTHON2_VERSION}/0110-mingw-_PyNode_SizeOf-decl-fix.patch
		$P/${PYTHON2_VERSION}/0115-mingw-cross-includes-lower-case.patch
		$P/${PYTHON2_VERSION}/0500-mingw-install-LDLIBRARY-to-LIBPL-dir.patch
		$P/${PYTHON2_VERSION}/0505-add-build-sysroot-config-option.patch
		$P/${PYTHON2_VERSION}/0510-cross-PYTHON_FOR_BUILD-gteq-275-and-fullpath-it.patch
		$P/${PYTHON2_VERSION}/0515-mingw-add-GetModuleFileName-path-to-PATH.patch
		$P/${PYTHON2_VERSION}/0520-Add-interp-Python-DESTSHARED-to-PYTHONPATH-b4-pybuilddir-txt-dir.patch
		$P/${PYTHON2_VERSION}/0525-msys-monkeypatch-os-system-via-sh-exe.patch
		$P/${PYTHON2_VERSION}/9999-re-configure-d.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]

	[[ ! -f $UNPACK_DIR/$P_V/post-patch.marker ]] && {
		pushd $UNPACK_DIR/$P_V > /dev/null
		echo -n "---> Executing..."
		rm -rf Modules/expat
		rm -rf Modules/_ctypes/libffi*
		rm -rf Modules/zlib
		autoconf > execute.log 2>&1
		autoheader >> execute.log 2>&1
		rm -rf autom4te.cache
		touch Include/graminit.h
		touch Python/graminit.c
		touch Parser/Python.asdl
		touch Parser/asdl.py
		touch Parser/asdl_c.py
		touch Include/Python-ast.h
		touch Python/Python-ast.c
		echo \"\" > Parser/pgen.stamp
		echo " done"
		touch post-patch.marker
		popd > /dev/null
	}
}

src_configure() {
	# Workaround for conftest error on 64-bit builds
	export ac_cv_working_tzset=no
	
	local _conf_flags=(
		--prefix=${PREFIX}
		--build=${HOST}
		--host=${HOST}
		--enable-shared
		--disable-ipv6
		--without-pydebug
		--with-system-expat
		--with-system-ffi
		CXX="$HOST-g++"
		LIBFFI_INCLUDEDIR="$PREFIX_WIN/lib/libffi-$LIBFFI_VERSION/include"
		OPT=""
		CFLAGS="\"$HOST_CFLAGS -fwrapv -DNDEBUG -D__USE_MINGW_ANSI_STDIO=1 -I$MINGWHOME_WIN/$HOST/include\""
		CXXFLAGS="\"$HOST_CFLAGS -fwrapv -DNDEBUG -D__USE_MINGW_ANSI_STDIO=1 -I$PREFIX_WIN/include -I$PREFIX_WIN/include/ncursesw -I$MINGWHOME_WIN/$HOST/include\""
		CPPFLAGS="\"$HOST_CPPFLAGS -I$PREFIX_WIN/include -I$PREFIX_WIN/include/ncursesw -I$MINGWHOME_WIN/$HOST/include\""
		LDFLAGS="\"-pipe -s -L$MINGWHOME_WIN/$HOST/lib -L$PREFIX_WIN/lib\""
	)
	local _allconf="${_conf_flags[@]}"
	func_configure $P_V $P_V "$_allconf"
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
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		${P_V} \
		"/bin/make" \
		"$_allinstall" \
		"installing..." \
		"installed"
	export PYTHONHOME=$PREFIX
}
