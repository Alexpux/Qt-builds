#!/bin/bash
set -e

P=perl
P_V=${P}-${PERL_VERSION}
EXT=".tar.gz"
SRC_FILE="${P_V}${EXT}"
URL=http://www.cpan.org/src/5.0/${SRC_FILE}
DEPENDS=(dmake)

change_paths() {
	OLD_PATH=$PATH
	export PATH=$MINGW_PART_PATH:$WINDOWS_PART_PATH:$MSYS_PART_PATH
}

restore_paths() {
	export PATH=$OLD_PATH
	unset OLD_PATH
}

src_download() {
	func_download $P_V $EXT $URL
}

src_unpack() {
	func_uncompress $P_V $EXT
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

	if [ -f $BUILD_DIR/$P_V/win32/configure.marker ]
	then
		echo "---> configured"
	else
		pushd $BUILD_DIR/$P_V/win32 > /dev/null
		echo -n "---> configure..."
		
		local DRV=`expr substr $MINGW_PERL_PREFIX_W 1 2`
		local NOTDRV=${MINGW_PERL_PREFIX_W#$DRV}
		NOTDRV=$(echo $NOTDRV | sed 's|/|\\\\|g')
		local MINGWHOME_WIN_P=$(echo $MINGWHOME_WIN | sed 's|/|\\\\|g')

		local COMMA=
		local EXTRA=$MINGWHOME_WIN/$TARGET/lib
		[[ $ARCHITECTURE == x32 ]] && {
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
	fi
}

pkg_build() {

	if [ -f $BUILD_DIR/$P_V/win32/make.marker ]
	then
		echo "---> Builded"
	else
		pushd $BUILD_DIR/$P_V/win32 > /dev/null
		echo "---> Building..."
		change_paths
		$MINGW_PERL_PREFIX_W/bin/dmake || die "Error building PERL"
		restore_paths
		echo " done"
		touch make.marker
		popd > /dev/null
	fi
}

pkg_install() {

	if [ -f $BUILD_DIR/$P_V/win32/install.marker ]
	then
		echo "---> Installed"
	else
		pushd $BUILD_DIR/$P_V/win32 > /dev/null
		echo "---> Installing..."
		change_paths
		$MINGW_PERL_PREFIX_W/bin/dmake install || die "Error installing PERL"
		restore_paths
		echo " done"
		touch install.marker
		popd > /dev/null
	fi
}
