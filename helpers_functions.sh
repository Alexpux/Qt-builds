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

die() {
	echo $@
	exit 1
}

# **************************************************************************

clear_env() {
	unset PKG_CONFIGURE
	unset PKG_LNDIR
	unset PKG_LNDIR_SRC
	unset PKG_LNDIR_DEST
	unset PKG_SRC_SUBDIR
	unset P_V
	unset P
	unset PKG_EXT
	unset PKG_SRC_FILE
	unset PKG_URL
	unset PKG_DEPENDS
	unset PKG_MAKE
	unset PKG_USE_CMAKE
	unset PKG_USE_QMAKE
}

# **************************************************************************

get_filename_extension() {
	local _fileext=
	local _filename=$1
	while [[ $_filename = ?*.* &&
         	( ${_filename##*.} = [A-Za-z]* || ${_filename##*.} = 7z ) ]]; do
		_fileext=${_filename##*.}.$_fileext
		_filename=${_filename%.*}
	done
	_fileext=${_fileext%.}
	echo "$_fileext"
}

# **************************************************************************

# install toolchains
toolchains_prepare() {

	local _file_mingw32=$(basename $URL_MINGW32)
	local _ext_mingw32=$(get_filename_extension $_file_mingw32)

	local _file_mingw64=$(basename $URL_MINGW64)
	local _ext_mingw64=$(get_filename_extension $_file_mingw64)

	pushd $TOOLCHAINS_DIR > /dev/null

	[[ ! -f $TOOLCHAINS_DIR/${_file_mingw32%.$_ext_mingw32}-unpack.marker ]] && {
		echo "-> Prepare 32-bit toolchain..."
		[[ -d $TOOLCHAINS_DIR/mingw32 ]] && {
			echo -n "--> Remove previous toolchain..."
			rm -rf $TOOLCHAINS_DIR/mingw32
			echo " done"
		}

		func_download ${_file_mingw32%.$_ext_mingw32} ".$_ext_mingw32" $URL_MINGW32
		func_uncompress ${_file_mingw32%.$_ext_mingw32} ".$_ext_mingw32" $TOOLCHAINS_DIR
		echo "--> Preparing 32-bit toolchain done"
	} || {
		echo "-> 32-bit toolchain prepared"
	}

	[[ ! -f $TOOLCHAINS_DIR/${_file_mingw64%.$_ext_mingw64}-unpack.marker ]] && {
		echo "-> Prepare 64-bit toolchain..."
		[[ -d $TOOLCHAINS_DIR/mingw64 ]] && {
			echo -n "--> Remove previous toolchain..."
			rm -rf $TOOLCHAINS_DIR/mingw64
			echo " done"
		}

		func_download ${_file_mingw64%.$_ext_mingw64} ".$_ext_mingw64" $URL_MINGW64
		func_uncompress ${_file_mingw64%.$_ext_mingw64} ".$_ext_mingw64" $TOOLCHAINS_DIR
		echo "--> Preparing 64-bit toolchain done"
	} || {
		echo "-> 64-bit toolchain prepared"
	}

	popd > /dev/null
}

# **************************************************************************

function func_absolute_to_relative {
	# $1 - first path
	# $2 - second path

	local _common=$1
	local _target=$2
	local _back=""

	while [[ "${_target#$_common}" == "${_target}" ]]; do
		_common=$(dirname $_common)
		_back="../${_back}"
	done

	[[ -z $_back ]] && {
		_back="./"
		echo "${_back}"
	} || {
		echo "${_back}${_target#$_common/}"
	}
}

# **************************************************************************

# download the sources
function func_download {
	# $1 - package name
	# $2 - sources type: .tar.gz, .tar.bz2 e.t.c...
	#      if sources get from a repository, choose it's type: cvs, svn, hg, git
	# $3 - URL
	# $4 - revision

	[[ -z $3 ]] && {
		die "URL is empty. terminate."
	}

	local _WGET_TIMEOUT=5
	local _WGET_TRIES=10
	local _WGET_WAIT=2
	local _result=0
	local _log_name=$MARKERS_DIR/${1//\//_}-download.log
	local _marker_name=$MARKERS_DIR/${1//\//_}-download.marker
	local _repo_update=no

	local _filename=$(basename $3)
	
	[[ "$2" == "cvs" || "$2" == "svn" || "$2" == "hg" || "$2" == "git" ]] && {
		local _lib_name=$UNPACK_DIR/$1
		if [[ $UPDATE_SOURCES == yes ]]
		then
			_repo_update=yes
		fi
	} || {
		local _lib_name=$SRC_DIR/$1
	}
	[[ ! -f $_marker_name || "$_repo_update" == "yes" ]] && {
		[[ -f $SRC_DIR/$_filename ]] && {
			echo -n "---> Delete corrupted download..."
			rm -f $SRC_DIR/$_filename
			echo " done"
		}
		pushd $SRC_DIR > /dev/null
		echo -n "---> download $1..."
		case $2 in
			cvs)
				#local _prev_dir=$PWD
				#cd $1
				[[ -n $4 ]] && {
					cvs -z9 -d $3 co -D$4 $1 > $_log_name 2>&1
				} || {
					cvs -z9 -d $3 co $1 > $_log_name 2>&1
				}
				#cd $_prev_dir
				_result=$?
			;;
			svn)
				[[ -d $_lib_name/.svn ]] && {
					pushd $_lib_name > /dev/null
					svn-clean -f > $_log_name 2>&1
					svn revert -R ./ >> $_log_name 2>&1
					svn up >> $_log_name 2>&1
					popd > /dev/null
				} || {
					[[ -n $4 ]] && {
						svn co -r $4 $3 $_lib_name > $_log_name 2>&1
					} || {
						svn co $3 $_lib_name > $_log_name 2>&1
					}
				}
				_result=$?
			;;
			hg)
				hg clone $3 $_lib_name > $_log_name 2>&1
				_result=$?
			;;
			git)
				[[ -d $_lib_name/.git ]] && {
					pushd $_lib_name > /dev/null
					git clean -f > $_log_name 2>&1
					git reset --hard >> $_log_name 2>&1
					git pull >> $_log_name 2>&1
					popd > /dev/null
				} || {
					[[ -n $4 ]] && {
						git clone --branch $4 $3 $_lib_name > $_log_name 2>&1
					} || {
						git clone $3 $_lib_name > $_log_name 2>&1
					}
				}
				_result=$?
			;;
			*)
				[[ ! -f $_marker_name && -f $_lib_name ]] && rm -rf $_lib_name
				wget \
					--tries=$_WGET_TRIES \
					--timeout=$_WGET_TIMEOUT \
					--wait=$_WGET_WAIT \
					--no-check-certificate \
					$3 > $_log_name 2>&1
				_result=$?
			;;
		esac
		popd > /dev/null
		[[ $_result == 0 ]] && {
			echo " done"
			touch $_marker_name
		} || {
			[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $_log_name &
			die " error $_result!"
		}
	} || {
		echo "---> downloaded"
	}
}

# uncompress sources
function func_uncompress {
	# $1 - name
	# $2 - ext
	# $3 - src dir name
	# $4 - ignore unpack errors

	local _src_dir=$UNPACK_DIR
	local _ignore_error=0
	local _marker_location=$MARKERS_DIR
	[[ "x$3" != "x" && "x$3" == "x--ignore" ]] && {
		_ignore_error=1
	}
	[[ "x$4" != "x" && "x$4" == "x--ignore" ]] && {
		_ignore_error=1
	}
	[[ "x$3" != "x" && "x$3" != "x--ignore" ]] && {
		_src_dir=$3
		_marker_location=$3
	}
	local _result=0
	local _unpack_cmd
	local _marker_name=$_marker_location/$1-unpack.marker
	local _log_name=$_marker_location/$1-unpack.log

	[[ $2 == .tar.gz || $2 == .tgz || $2 == .tar.bz2 || $2 == .tar.lzma \
	|| $2 == .tar.xz || $2 == .tar.7z || $2 == .7z || $2 == .zip ]] && {
		[[ ! -f $_marker_name ]] && {
			echo -n "---> unpack..."
			case $2 in
				.tar.gz|.tgz) _unpack_cmd="tar xvf $SRC_DIR/$1$2 -C $_src_dir > $_log_name 2>&1" ;;
				.tar.bz2) _unpack_cmd="tar xvjf $SRC_DIR/$1$2 -C $_src_dir > $_log_name 2>&1" ;;
				.tar.lzma) _unpack_cmd="tar xvJf $SRC_DIR/$1$2 -C $_src_dir > $_log_name 2>&1" ;;
				.tar.xz) _unpack_cmd="tar -xv --xz -f $SRC_DIR/$1$2 -C $_src_dir > $_log_name 2>&1" ;;
				.tar.7z) die "unimplemented. terminate." ;;
				.7z) _unpack_cmd="7za x -y $SRC_DIR/$1$2 -o$_src_dir > $_log_name 2>&1" ;;
				.zip) _unpack_cmd="unzip $SRC_DIR/$1$2 -d $_src_dir > $_log_name 2>&1" ;;
				*) die " error. bad archive type: $2" ;;
			esac
			eval ${_unpack_cmd}
			_result=$?
			[[ $_result == 0 || $_ignore_error == 1 ]] && {
				echo " done"
				touch $_marker_name
			} || {
				[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $_log_name &
				die " error $_result!"
			}
		} || {
			echo "---> unpacked"
		}
	}
}

# **************************************************************************

# create copy of sources in build directory
function lndirs() {
	local _src_dir=$UNPACK_DIR
	local _dest_dir=$BUILD_DIR
	[[ -n $PKG_LNDIR_SRC ]] && {
		_src_dir=$_src_dir/$PKG_LNDIR_SRC
	} || {
		_src_dir=$_src_dir/$P_V
	}
	[[ -n $PKG_LNDIR_DEST ]] && {
		_dest_dir=$_dest_dir/$PKG_LNDIR_DEST
	} || {
		_dest_dir=$_dest_dir/$P_V
	}

	[[ ! -f $_dest_dir/lndirs.marker ]] && {
		echo -n "---> Copy sources to build directory..."
		mkdir -p $_dest_dir
		lndir $_src_dir $_dest_dir > $LOG_DIR/${P_V}-lndirs.log 2>&1 || die "Fail lndir sources"
		touch $_dest_dir/lndirs.marker
		echo " done"
	} || {
		echo "---> Sources already copied"
	}
}

# **************************************************************************

# apply list of patches
function func_apply_patches {
	# $1 - patches list
	# $2 - sources directory
	
	local _src_dir=$UNPACK_DIR/$P_V
	[[ -n $2 ]] && {
		_src_dir=$2
	}
	
	local _result=0
	local _index=0
	local -a _list=( "${!1}" )
	[[ ${#_list[@]} == 0 ]] && {
		echo "---> No patches for $P_V"
		return 0
	}

	_index=$((${#_list[@]}-1))
	[[ -f $_src_dir/_patch-$_index.marker ]] && {
		echo "---> patched"
		return 0
	}
	_index=0

	[[ ${#_list[@]} > 0 ]] && {
		echo -n "---> patching..."
	}

	local it=
	local applevel=
	pushd $_src_dir > /dev/null
	for it in ${_list[@]} ; do
		local _patch_marker_name=$_src_dir/_patch-$_index.marker

		[[ ! -f $_patch_marker_name ]] && {
			[[ -f $PATCH_DIR/${it} ]] || die "Patch $PATCH_DIR/${it} not found!"
			local level=
			local found=no
			for level in 0 1 2 3 4
			do
				applevel=$level
				if patch -p$level --dry-run -i $PATCH_DIR/${it} > $_src_dir/patch-$_index.log 2>&1
				then
					found=yes
					break
				fi
			done
			[[ $found == "yes" ]] && {
				patch -p$applevel -i $PATCH_DIR/${it} > $_src_dir/patch-$_index.log 2>&1
				touch $_patch_marker_name
			} || {
				_result=1
				break
			}
		}
		_index=$(($_index+1))
	done
	popd > /dev/null

	[[ $_result == 0 ]] && {
		echo " done"
	} || {
		[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $_src_dir/patch-$_index.log &
		die "Failed to apply patch ${it} at level $applevel"
	}
}

# **************************************************************************

# configure
function func_configure {
	# $1 - configure flags

	local _src_dir=$UNPACK_DIR
	local _bld_dir=$BUILD_DIR

	[[ -n $PKG_LNDIR_DEST ]] && {
		local _bld_dir=$_bld_dir/$PKG_LNDIR_DEST
	} || {
		local _bld_dir=$_bld_dir/$P_V
		local _src_dir=$_src_dir/$P_V
	}
	
	[[ -n $PKG_SRC_SUBDIR ]] && {
		_bld_dir=$_bld_dir/$PKG_SRC_SUBDIR
		_src_dir=$_src_dir/$PKG_SRC_SUBDIR
		local _log_name=$LOG_DIR/${P_V}_${PKG_SRC_SUBDIR//\//_}-configure.log
	} || {
		local _log_name=$LOG_DIR/${P_V}-configure.log
	}

	[[ $PKG_LNDIR == yes ]] && {
		lndirs
		local _rell="."
	} || {
		local _rell=$( func_absolute_to_relative $_bld_dir $_src_dir )
	}

	local _marker=$_bld_dir/_configure.marker
	local _result=0
	
	local _conf_cmd="${_rell}/${PKG_CONFIGURE} ${1}"
	[[ $PKG_USE_CMAKE == yes ]] && {
		local _conf_cmd="cmake ${_rell} ${1}"
	}
	[[ $PKG_USE_QMAKE == yes ]] && {
		local _conf_cmd="qmake ${_rell}/${PKG_CONFIGURE} ${1}"
	}
	
	[[ ! -f $_marker ]] && {
		mkdir -p $_bld_dir
		echo -n "---> configure..."
		pushd $_bld_dir > /dev/null
		
		eval ${_conf_cmd} > $_log_name 2>&1
		_result=$?
		[[ $_result == 0 ]] && {
			echo " done"
			touch $_marker
		} || {
			[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $_log_name &
			die " error $_result!"
		}
		popd > /dev/null
	} || {
		echo "---> configured"
	}
}
# **************************************************************************

# make
function func_make {
	# $1 - make flags
	# $2 - text
	# $3 - text if completed

	local _bld_dir=$BUILD_DIR

	[[ -n $PKG_LNDIR_DEST ]] && {
		local _bld_dir=$_bld_dir/$PKG_LNDIR_DEST
	} || {
		local _bld_dir=$_bld_dir/$P_V
	}
	
	[[ -n $PKG_SRC_SUBDIR ]] && {
		_bld_dir=$_bld_dir/$PKG_SRC_SUBDIR
		local _log_name=$LOG_DIR/${P_V}_${PKG_SRC_SUBDIR//\//_}-$3.log
	} || {
		local _log_name=$LOG_DIR/${P_V}-$3.log
	}
	
	local _marker=$_bld_dir/_$3.marker
	local _result=0
	
	local _make_cmd="$PKG_MAKE $1"

	[[ ! -f $_marker ]] && {
		echo -n "---> $2..."
		( cd $_bld_dir && eval ${_make_cmd} > $_log_name 2>&1 )
		_result=$?
		[[ $_result == 0 ]] && {
			echo " done"
			touch $_marker
		} || {
			[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $_log_name &
			die " error $_result!"
		}
	} || {
		echo "---> $3"
	}
}

# **************************************************************************
