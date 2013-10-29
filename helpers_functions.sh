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

function func_show_log {
	# $1 - log file
	[[ $SHOW_LOG_ON_ERROR == yes ]] && $LOGVIEWER $1 &
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
	unset PKG_TYPE
	unset PKG_SRC_FILE
	unset PKG_URL
	unset PKG_DEPENDS
	unset PKG_MAKE
	unset PKG_USE_CMAKE
	unset PKG_USE_QMAKE
	unset PKG_UNCOMPRESS_SKIP_ERRORS
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

func_get_filename_extension() {
	# $1 - filename
	
	local _filename=$1
	local _ext=
	local _finish=0
	case "${_filename##*.}" in
		bz2|gz|lzma|xz) 
			_ext=$_ext'.'${_filename##*.}
			_filename=${_filename%$_ext}
			local _sub_ext=$(func_get_filename_extension $_filename)
			[[ "$_sub_ext" == ".tar" ]] && _ext=$_sub_ext$_ext
		;;
		*)
			_ext='.'${_filename##*.}
		;;
	esac
	echo "$_ext"
}

# **************************************************************************

function func_abstract_toolchain {
	# $1 - toolchain URL
	# $2 - install path
	# $3 - toolchain arch
	local -a _url=( "$1|root:$TOOLCHAINS_DIR" )
	local _filename=$(basename $1)
	local _do_install=no

	echo -e "-> \E[32;40m$3 toolchain\E[37;40m"
	[[ ! -f $MARKERS_DIR/${_filename}-unpack.marker ]] && {
		[[ -d $2 ]] && {
			echo "---> Found previously installed $3 toolchain."
			echo -n "-----> Remove previous $3 toolchain..."
			rm -rf $2
			echo " done"
		} || {
			echo -n "---> $3 toolchain is not installed."
		}
		func_download _url[@]
		func_uncompress _url[@]
	} || {
		echo "---> Toolchain installed."
	}
}

# install toolchains
toolchains_prepare() {
	func_abstract_toolchain $URL_MINGW32 $TOOLCHAINS_DIR/mingw32 "i686"
	func_abstract_toolchain $URL_MINGW64 $TOOLCHAINS_DIR/mingw64 "x86_64"
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
	[[ -n $1 ]] && {
		local -a _list=( "${!1}" )
	} || {
		local -a _list=${PKG_URL}
	}
	[[ ${#_list[@]} == 0 ]] && {
		echo "---> Doesn't need to download."
		return 0
	}

	local _WGET_TIMEOUT=5
	local _WGET_TRIES=10
	local _WGET_WAIT=2
	local _result=0
	local _it=
	
	for _it in ${_list[@]} ; do
		local _params=( ${_it//|/ } )

		local _filename=
		local _marker_name=
		local _log_name=
		local _url=${_params[0]}
		local _repo=
		local _branch=
		local _rev=
		local _dir=
		local _root=$SRC_DIR
		local _module=
		local _lib_name=$UNPACK_DIR/$P_V
		
		local _index=1
		while [ "$_index" -lt "${#_params[@]}" ]; do
			local _params2=( $(echo ${_params[$_index]} | sed 's|:| |g') )
			case ${_params2[0]} in
				branch) _branch=${_params2[1]} ;;
				dir)    _dir=${_params2[1]} ;;
				module) _module=${_params2[1]} ;;
				repo)   _repo=${_params2[1]} ;;
				rev)    _rev=${_params2[1]} ;;
				root)   _root=${_params2[1]} ;;
			esac
			_index=$(($_index+1))
		done

		local _repo_update=no
		local _is_repo=no
		case $_repo in
			cvs|svn|git|hg)
				_is_repo=yes
				if [[ $UPDATE_SOURCES = "yes" ]]; then
					_repo_update=yes
				fi
				if ( [[ -n $_module ]] && [[ -n $_repo ]] ); then
					_filename=$_module
				fi
			;;
			*)
				_filename=$(basename ${_url})
			;;
		esac

		_log_name=$MARKERS_DIR/${_filename//\//_}-download.log
		_marker_name=$MARKERS_DIR/${_filename//\//_}-download.marker

		[[ ! -f $_marker_name || $_repo_update == yes ]] && {
			[[ $_is_repo == yes ]] && {
				echo -n "---> checkout $_filename..."

				[[ -n $_dir ]] && { _lib_name=$_lib_name/$_dir; }
				[[ -n $_filename ]] && { _lib_name=$_lib_name/$_filename; }
				case $_repo in
					cvs)
						local _prev_dir=$PWD
						cd $UNPACK_DIR
						[[ -n $_rev ]] && {
							cvs -z9 -d $_url co -D$_rev $_module > $_log_name 2>&1
						} || {
							cvs -z9 -d $_url co $_module > $_log_name 2>&1
						}
						cd $_prev_dir
						_result=$?
					;;
					svn)
						[[ -d $_lib_name/.svn ]] && {
							pushd $_lib_name > /dev/null
							svn-clean -f > $_log_name 2>&1
							svn revert -R ./ >> $_log_name 2>&1
							[[ -n $_rev ]] && {
								svn up -r $_rev >> $_log_name 2>&1
							} || {
								svn up >> $_log_name 2>&1
							}
							popd > /dev/null
						} || {
							[[ -n $_rev ]] && {
								svn co -r $_rev $_url $_lib_name > $_log_name 2>&1
							} || {
								svn co $_url $_lib_name > $_log_name 2>&1
							}
						}
						_result=$?
					;;
					hg)
						hg clone $_url $_lib_name > $_log_name 2>&1
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
							[[ -n $_branch ]] && {
								git clone --branch $_branch $_url $_lib_name > $_log_name 2>&1
							} || {
								git clone $_url $_lib_name > $_log_name 2>&1
							}
						}
						_result=$?
					;;
				esac	
			} || {
				_lib_name=$SRC_DIR/$_filename
				[[ -f $_lib_name ]] && {
					echo -n "---> Delete corrupted download..."
					rm -f $_filename
					echo " done"
				}
				echo -n "---> download $_filename..."
				wget \
					--tries=$_WGET_TRIES \
					--timeout=$_WGET_TIMEOUT \
					--wait=$_WGET_WAIT \
					--no-check-certificate \
					$_url -O $_lib_name > $_log_name 2>&1
				_result=$?
			}
			[[ $_result == 0 ]] && {
				echo " done"
				touch $_marker_name
			} || {
				func_show_log $_log_name
				die " error $_result" $_result
			}
		} || {
			echo "---> $_filename downloaded"
		}	
	done
}

# uncompress sources
function func_uncompress {
	[[ -n $1 ]] && {
		local -a _list=( "${!1}" )
	} || {
		local -a _list=${PKG_URL}
	}
	local _it=
	[[ ${#_list[@]} == 0 ]] && {
		echo "---> Unpack doesn't need."
		return 0
	}

	for _it in ${_list[@]} ; do
		local _params=( ${_it//|/ } )
		local _result=0
		local _unpack_cmd
		local _marker_name=
		local _log_name=
		local _filename=
		local _ext=
		local _url=${_params[0]}
		local _module=
		local _dir=
		local _root=$UNPACK_DIR
		local _lib_name=
		
		local _index=1
		while [ "$_index" -lt "${#_params[@]}" ]
		do
			local _params2=( $(echo ${_params[$_index]} | sed 's|:| |g') )
			case ${_params2[0]} in
				dir)    _dir=${_params2[1]} ;;
				root)   _root=${_params2[1]} ;;
				module) _module=${_params2[1]} ;;
			esac
			_index=$(($_index+1))
		done

		_lib_name=${_root}/${_dir}
		_filename=$(basename ${_params[0]})
		local _log_dir=$MARKERS_DIR
		[[ -n $2 ]] && {
			_log_dir=$2
		}
		_log_name=$_log_dir/${_filename}-unpack.log
		_marker_name=$_log_dir/${_filename}-unpack.marker
		_ext=$(func_get_filename_extension $_filename)
		[[ $_ext == .tar.gz || $_ext == .tar.bz2 || $_ext == .tar.lzma || $_ext == .tar.xz \
		|| $_ext == .tar.7z || $_ext == .7z || $_ext == .tgz || $_ext == .zip ]] && {
			[[ ! -f $_marker_name ]] && {
				echo -n "---> unpack $_filename..."
				case $_ext in
					.tar.gz|.tgz) _unpack_cmd="tar xvf $SRC_DIR/$_filename -C $_lib_name > $_log_name 2>&1" ;;
					.tar.bz2) _unpack_cmd="tar xvjf $SRC_DIR/$_filename -C $_lib_name > $_log_name 2>&1" ;;
					.tar.lzma|.tar.xz) _unpack_cmd="tar xvJf $SRC_DIR/$_filename -C $_lib_name > $_log_name 2>&1" ;;
					.tar.7z) die "unimplemented. terminate." ;;
					.7z) _unpack_cmd="7za x $SRC_DIR/$_filename -o$_lib_name > $_log_name 2>&1" ;;
					.zip) _unpack_cmd="unzip $SRC_DIR/$_filename -d $_lib_name > $_log_name 2>&1" ;;
					*) die " error. bad archive type: $_ext" ;;
				esac
				eval ${_unpack_cmd}
				_result=$?
				[[ $_result == 0 ]] && {
					echo " done"
					touch $_marker_name
				} || {
					func_show_log $_log_name
					die " error $_result" $_result
				}
			} || {
				echo "---> $_filename unpacked"
			}
		}
	done
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
		func_show_log $_src_dir/patch-$_index.log
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
		_bld_dir=$_bld_dir/$PKG_LNDIR_DEST
	} || {
		_bld_dir=$_bld_dir/$P_V
		_src_dir=$_src_dir/$P_V
	}
	
	[[ -n $PKG_SRC_SUBDIR ]] && {
		_bld_dir=$_bld_dir/$PKG_SRC_SUBDIR
		_src_dir=$_src_dir/$PKG_SRC_SUBDIR
		local _log_name=$LOG_DIR/${P_V}_${PKG_SRC_SUBDIR//\//_}-configure.log
	} || {
		_src_dir=$_src_dir/$P_V
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
		_conf_cmd="cmake ${_rell} ${1}"
	}
	[[ $PKG_USE_QMAKE == yes ]] && {
		_conf_cmd="qmake ${_rell}/${PKG_CONFIGURE} ${1}"
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
			func_show_log $_log_name
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
			func_show_log $_log_name
			die " error $_result!"
		}
	} || {
		echo "---> $3"
	}
}

# **************************************************************************
