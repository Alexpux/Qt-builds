#!/bin/bash
set -e

P=perl
P_V=${P}-${PERL_VERSION}
SRC_FILE="${P_V}.tar.gz"
URL=http://www.cpan.org/src/5.0/${SRC_FILE}
DEPENDS=(dmake)

change_paths() {
	OLD_PATH=$PATH
	export PATH=$PREFIX/bin:$MINGWHOME/bin:$WINDOWS_PART_PATH:$MSYS_PART_PATH
}

restore_paths() {
	export PATH=$OLD_PATH
	unset OLD_PATH
}

src_download() {
	func_download $P_V ".tar.gz" $URL
}

src_unpack() {
	func_uncompress $P_V ".tar.gz"
}

src_patch() {
	local _patches=(
		$P/perl-mingw.patch
		$P/perl-variables.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
	
	
	cp $SRC_DIR/$P_V/win32/makefile.mk $SRC_DIR/$P_V/win32/makefile.mk.patched
}

src_configure() {
	
	cp -rf $SRC_DIR/$P_V $BUILD_DIR/
	
	pushd $BUILD_DIR/$P_V/win32 > /dev/null
	
	if [ -f configure.marker ]
	then
		echo "--> Configured"
	else
		echo "--> Configure..."
		
		local PERL_PREFIX=$PREFIX_WIN/perl
		local DRV=`expr substr $PERL_PREFIX 1 2`
		local NOTDRV=${PERL_PREFIX#$DRV}
		NOTDRV=$(echo $NOTDRV | sed 's|/|\\\\|g')
		local MINGWHOME_WIN_P=$(echo $MINGWHOME_WIN | sed 's|/|\\\\|g')

		local COMMA=
		local EXTRA=
		#local WIN_SYS=
		[[ $ARCHITECTURE == x32 ]] && {
			COMMA=""
			EXTRA=$MINGWHOME_WIN/i686-w64-mingw32/lib
		} || {
			COMMA="#"
			EXTRA=$MINGWHOME_WIN/x86_64-w64-mingw32/lib
		}
		EXTRA=$(echo $EXTRA | sed 's|/|\\\\|g')

		# pushd $SYSTEMROOT > /dev/null
			# WIN_SYS=`pwd`
		# popd > /dev/null
		#OLD_PATH=$PATH

		#MSYS_SYS=.:/usr/local/bin:/bin
		
		cat makefile.mk | sed 's|%DRV%|'"$DRV"'|g' \
			| sed -e 's|%NODRV%|'"$NOTDRV"'|g' \
			| sed -e 's|%COMW64%|'"$COMMA"'|g' \
			| sed -e 's|%MINGWHOME%|'"$MINGWHOME_WIN_P"'|g' \
			| sed -e 's|%THIRDPARTY_LIBS%|'"$EXTRA"'|g' > makefile.tmp

		rm -f makefile.mk
		mv makefile.tmp makefile.mk
		echo "done"
	fi
	touch configure.marker
	
	popd > /dev/null
}

pkg_build() {
	
	pushd $BUILD_DIR/$P_V/win32 > /dev/null
	
	if [ -f make.marker ]
	then
		echo "--> Builded"
	else
		echo "--> Building..."
		change_paths
		dmake || exit 1
		restore_paths
		echo "done"
	fi
	touch make.marker
	
	popd > /dev/null
}

pkg_install() {
	pushd $BUILD_DIR/$P_V/win32 > /dev/null
	
	if [ -f install.marker ]
	then
		echo "--> Installed"
	else
		echo "--> Installing..."
		change_paths
		dmake install || exit 1
		restore_paths
		echo "done"
	fi
	touch install.marker
	
	popd > /dev/null
}
