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
PKG_TYPE=".tar.bz2"
PKG_SRC_FILE="${P_V}${PKG_TYPE}"
PKG_URL=(
	"http://www.python.org/ftp/python/${PYTHON2_VERSION}/$PKG_SRC_FILE"
)
PKG_DEPENDS=("expat" "libffi" "zlib")

src_download() {
	func_download
}

src_unpack() {
	func_uncompress
}

src_patch() {
	local _patches=(
		$P/${PYTHON2_VERSION}/0100-MINGW-BASE-use-NT-thread-model.patch
		$P/0110-MINGW-translate-gcc-internal-defines-to-python-platf.patch
		$P/0120-MINGW-use-header-in-lowercase.patch
		$P/0130-MINGW-configure-MACHDEP-and-platform-for-build.patch
		$P/0140-MINGW-preset-configure-defaults.patch
		$P/0150-MINGW-configure-largefile-support-for-windows-builds.patch
		$P/0160-MINGW-add-wincrypt.h-in-Python-random.c.patch
		$P/0180-MINGW-init-system-calls.patch
		$P/0190-MINGW-detect-REPARSE_DATA_BUFFER.patch
		$P/0200-MINGW-build-in-windows-modules-winreg.patch
		$P/0210-MINGW-determine-if-pwdmodule-should-be-used.patch
		$P/0220-MINGW-default-sys.path-calculations-for-windows-plat.patch
		$P/0230-MINGW-AC_LIBOBJ-replacement-of-fileblocks.patch
		$P/0250-MINGW-compiler-customize-mingw-cygwin-compilers.patch
		$P/0270-CYGWIN-issue13756-Python-make-fail-on-cygwin.patch
		$P/0280-issue17219-add-current-dir-in-library-path-if-buildi.patch
		$P/0290-issue6672-v2-Add-Mingw-recognition-to-pyport.h-to-al.patch
		$P/0300-MINGW-configure-for-shared-build.patch
		$P/0310-MINGW-dynamic-loading-support.patch
		$P/0320-MINGW-implement-exec-prefix.patch
		$P/0330-MINGW-ignore-main-program-for-frozen-scripts.patch
		$P/0340-MINGW-setup-exclude-termios-module.patch
		$P/0350-MINGW-setup-_multiprocessing-module.patch
		$P/0360-MINGW-setup-select-module.patch
		$P/0370-MINGW-setup-_ctypes-module-with-system-libffi.patch
		$P/0380-MINGW-defect-winsock2-and-setup-_socket-module.patch
		$P/0390-MINGW-exclude-unix-only-modules.patch
		$P/0400-MINGW-setup-msvcrt-module.patch
		$P/0410-MINGW-build-extensions-with-GCC.patch
		$P/0420-MINGW-use-Mingw32CCompiler-as-default-compiler-for-m.patch
		$P/0430-MINGW-find-import-library.patch
		$P/0440-MINGW-setup-_ssl-module.patch
		$P/0450-MINGW-export-_PyNode_SizeOf-as-PyAPI-for-parser-modu.patch
		$P/0460-MINGW-generalization-of-posix-build-in-sysconfig.py.patch
		$P/0462-MINGW-support-stdcall-without-underscore.patch
		$P/0480-MINGW-generalization-of-posix-build-in-distutils-sys.patch
		$P/0490-MINGW-customize-site.patch
		$P/0500-add-python-config-sh.patch
		$P/0510-cross-darwin-feature.patch
		$P/0520-py3k-mingw-ntthreads-vs-pthreads.patch
		$P/0530-mingw-system-libffi.patch
		$P/0540-mingw-semicolon-DELIM.patch
		$P/0550-mingw-regen-use-stddef_h.patch
		$P/0560-mingw-use-posix-getpath.patch
		$P/0565-mingw-add-ModuleFileName-dir-to-PATH.patch
		$P/0570-mingw-add-BUILDIN_WIN32_MODULEs-time-msvcrt.patch
		$P/0580-mingw32-test-REPARSE_DATA_BUFFER.patch
		$P/0590-mingw-INSTALL_SHARED-LDLIBRARY-LIBPL.patch
		$P/0600-msys-mingw-prefer-unix-sep-if-MSYSTEM.patch
		$P/0610-msys-cygwin-semi-native-build-sysconfig.patch
		$P/0620-mingw-sysconfig-like-posix.patch
		$P/0630-mingw-_winapi_as_builtin_for_Popen_in_cygwinccompiler.patch
		$P/0640-mingw-x86_64-size_t-format-specifier-pid_t.patch
		$P/0650-cross-dont-add-multiarch-paths-if-cross-compiling.patch
		$P/0660-mingw-use-backslashes-in-compileall-py.patch
		$P/0670-msys-convert_path-fix-and-root-hack.patch
		$P/0690-allow-static-tcltk.patch
		$P/0710-CROSS-properly-detect-WINDOW-_flags-for-different-nc.patch
		$P/0720-mingw-pdcurses_ISPAD.patch
		$P/0740-grammar-fixes.patch
		$P/0750-Add-interp-Python-DESTSHARED-to-PYTHONPATH-b4-pybuilddir-txt-dir.patch
		$P/0760-msys-monkeypatch-os-system-via-sh-exe.patch
		$P/0770-msys-replace-slashes-used-in-io-redirection.patch
		$P/0790-mingw-add-_exec_prefix-for-tcltk-dlls.patch
		$P/0800-mingw-install-layout-as-posix.patch
		$P/0820-mingw-reorder-bininstall-ln-symlink-creation.patch
		$P/0830-add-build-sysroot-config-option.patch
		$P/0840-add-builddir-to-library_dirs.patch
		$P/0850-cross-PYTHON_FOR_BUILD-gteq-276-and-fullpath-it.patch
		$P/1000-dont-link-with-gettext.patch
		$P/1010-ctypes-python-dll.patch
		$P/1020-gdbm-module-includes.patch
		$P/1030-use-gnu_printf-in-format.patch
	)
	
	func_apply_patches \
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
	local _install_flags=(
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		"$_allinstall" \
		"installing..." \
		"installed"
	export PYTHONHOME=$PREFIX
}
