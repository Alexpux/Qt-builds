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

PACKAGES=(
	pkg-config
	zlib
	gperf
	libgnurx
	bzip2
	lzo
	ncurses
	readline
	xz
	expat
	sqlite
	$( [[ $STATIC_DEPS == no ]] \
		&& echo "pcre \
				 icu \
				 libiconv \
				 libxml2 \
				 libxslt" \
	)
	openssl
	$( [[ $USE_PYTHON == self ]] \
		&& echo "libffi python2" \
	)
	yaml
 	$( [[ $BUILD_RUBY == yes ]] \
		&& echo "ruby" \
	)
 	$( [[ $BUILD_PERL == yes ]] \
		&& echo "dmake \
				 perl" \
	)
	# gettext
	$( [[ $STATIC_DEPS == no ]] \
		&& echo "freetype \
				 fontconfig" \
	)
	$( [[ $BUILD_EXTRA_STUFF == yes && $STATIC_DEPS == no ]] \
		&& echo "nasm \
				libjpeg-turbo \
				libpng \
				jbigkit \
				freeglut \
				tiff \
				libidn \
				libssh2 \
				curl \
				libarchive \
				cmake" \
	)
	qt-$QT_VERSION
	qtbinpatcher
 	$( [[ $STATIC_DEPS == yes ]] \
		&& echo "installer-framework" \
	)
	$( [[ $STATIC_DEPS == no ]] \
		&& echo "qbs" \
	)
	$( [[ $BUILD_QTCREATOR == yes ]] \
		&& echo "qt-creator" \
	)
	$( [[ $BUILD_EXTRA_STUFF == yes && $STATIC_DEPS == no ]] \
		&& echo "poppler-data \
				poppler" \
	)
)
