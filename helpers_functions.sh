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

	pushd $TOOLCHAINS_DIR > /dev/null
	if [ -f toolchains.marker ]
	then
		echo "-> Toolchains prepared"
	else
		echo "-> Prepare toolchains..."

		local _file_mingw32=$(basename $URL_MINGW32)
		local _ext_mingw32=$(get_filename_extension $_file_mingw32)
		func_download mingw32 ".$_ext_mingw32" $URL_MINGW32
		func_uncompress ${_file_mingw32%.$_ext_mingw32} ".$_ext_mingw32" $TOOLCHAINS_DIR
		
		local _file_mingw64=$(basename $URL_MINGW64)
		local _ext_mingw64=$(get_filename_extension $_file_mingw64)
		func_download mingw64 ".$_ext_mingw64" $URL_MINGW64
		func_uncompress ${_file_mingw64%.$_ext_mingw64} ".$_ext_mingw64" $TOOLCHAINS_DIR
		
		echo "--> Preparing done"
	fi
	touch toolchains.marker
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

	echo "${_back}${_target#$_common/}"
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
	local _log_name=$MARKERS_DIR/$1-download.log
	local _marker_name=$MARKERS_DIR/$1-download.marker

	local _lib_name=$SRC_DIR/$1
	local _filename=$(basename $3)
	
	# [[ $3 == cvs || $3 == svn || $3 == hg || $3 == git ]] && {
		# local _lib_name=$1/$2
	# } || {
		# local _lib_name=$1/$2$3
	# }
	[[ ! -f $_marker_name ]] && {
		[[ -f $SRC_DIR/$_filename ]] && {
			echo -n "--> Delete corrupted download..."
			rm -f $SRC_DIR/$_filename
			echo " done"
		}
		pushd $SRC_DIR > /dev/null
		echo -n "--> download $1 ..."
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
				[[ -n $4 ]] && {
					svn co -r $4 $3 $_lib_name > $_log_name 2>&1
				} || {
					svn co $3 $_lib_name > $_log_name 2>&1
				}
				_result=$?
			;;
			hg)
				hg clone $3 $_lib_name > $_log_name 2>&1
				_result=$?
			;;
			git)
				git clone $3 $_lib_name > $_log_name 2>&1
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

	local _src_dir=$SRC_DIR
	local _marker_location=$MARKERS_DIR
	[[ "x$3" != "x" ]] && {
		_src_dir=$3
		_marker_location=$3
	}
	local _result=0
	local _unpack_cmd
	local _marker_name=$_marker_location/$1-unpack.marker
	local _log_name=$_marker_location/$1-unpack.log

	[[ $2 == .tar.gz || $2 == .tgz || $2 == .tar.bz2 || $2 == .tar.lzma \
	|| $2 == .tar.xz || $2 == .tar.7z || $2 == .7z ]] && {
		[[ ! -f $_marker_name ]] && {
			echo -n "--> unpack..."
			case $2 in
				.tar.gz|.tgz) _unpack_cmd="tar xvf $SRC_DIR/$1$2 -C $_src_dir > $_log_name 2>&1" ;;
				.tar.bz2) _unpack_cmd="tar xvjf $SRC_DIR/$1$2 -C $_src_dir > $_log_name 2>&1" ;;
				.tar.lzma) _unpack_cmd="tar xvJf $SRC_DIR/$1$2 -C $_src_dir > $_log_name 2>&1" ;;
				.tar.xz) _unpack_cmd="tar -xv --xz -f $SRC_DIR/$1$2 -C $_src_dir > $_log_name 2>&1" ;;
				.tar.7z) die "unimplemented. terminate." ;;
				.7z) _unpack_cmd="7za x $SRC_DIR/$1$2 -o$_src_dir > $_log_name 2>&1" ;;
				*) die " error. bad archive type: $2" ;;
			esac
			eval ${_unpack_cmd}
			_result=$?
			[[ $_result == 0 ]] && {
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

# apply list of patches
function func_apply_patches {
	# $1 - src dir name
	# $2 - patches list
	# $3 - sources directory
	
	local _src_dir=$SRC_DIR
	[[ "x$3" != "x" ]] && {
		_src_dir=$3
	}
	
	local _result=0
	local _index=0
	local -a _list=( "${!2}" )
	[[ ${#_list[@]} == 0 ]] && return 0

	((_index=${#_list[@]}-1))
	[[ -f $_src_dir/$1/_patch-$_index.marker ]] && {
		echo "---> patched"
		return 0
	}
	_index=0

	[[ ${#_list[@]} > 0 ]] && {
		echo -n "--> patching..."
	}

	for it in ${_list[@]} ; do
		local _patch_marker_name=$_src_dir/$1/_patch-$_index.marker

		[[ ! -f $_patch_marker_name ]] && {
			( cd $_src_dir/$1 && patch -p1 < $PATCH_DIR/${it} > $_src_dir/$1/patch-$_index.log 2>&1 )
			_result=$?
			[[ $_result == 0 ]] && {
				touch $_patch_marker_name
			} || {
				_result=1
				break
			}
		}
		((_index++))
	done

	[[ $_result == 0 ]] && {
		echo "done"
	} || {
		[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $_src_dir/$1/patch-$_index.log &
		die " error $_result!"
	}
}

# **************************************************************************

# configure
function func_configure {
	# $1 - build dir name
	# $2 - src dir name
	# $3 - flags
	# $4 - parent source directory (set if it not $SRC_DIR)

	local _src_dir=$SRC_DIR/$2
	[[ "x$4" != "x" ]] && {
		_src_dir=$4/$2
	}

	local _marker=$BUILD_DIR/$1/_configure.marker
	local _result=0
	local _log_name=$LOG_DIR/${2//\//_}-configure.log

	[[ ! -f $_marker ]] && {
		echo -n "--> configure..."
		mkdir -p $BUILD_DIR/$1
		( cd $BUILD_DIR/$1 && eval $( func_absolute_to_relative $BUILD_DIR/$1 $_src_dir )/configure "${3}" > $_log_name 2>&1 )
		_result=$?
		[[ $_result == 0 ]] && {
			echo " done"
			touch $_marker
		} || {
			[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $_log_name &
			die " error $_result!"
		}
	} || {
		echo "---> configured"
	}
}
# **************************************************************************

# make
function func_make {
	# $1 - build dir name
	# $2 - make prog name
	# $3 - make flags
	# $4 - text
	# $5 - text if completed
	# $6 - index

	local _marker=$BUILD_DIR/$1/_$5$6.marker
	local _result=0
	local _log_name=$LOG_DIR/$1-$5$6.log
	
	local _make_cmd="$2 $3"

	[[ ! -f $_marker ]] && {
		echo -n "--> $4..."
		( cd $BUILD_DIR/$1 && eval ${_make_cmd} > $_log_name 2>&1 )
		_result=$?
		[[ $_result == 0 ]] && {
			echo " done"
			touch $_marker
		} || {
			[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $_log_name &
			die " error $_result!"
		}
	} || {
		echo "---> $5"
	}
}

# **************************************************************************
