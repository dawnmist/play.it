#!/bin/sh -e
set -o errexit

###
# Copyright (c) 2015-2018, Antoine Le Gonidec
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# This software is provided by the copyright holders and contributors "as is"
# and any express or implied warranties, including, but not limited to, the
# implied warranties of merchantability and fitness for a particular purpose
# are disclaimed. In no event shall the copyright holder or contributors be
# liable for any direct, indirect, incidental, special, exemplary, or
# consequential damages (including, but not limited to, procurement of
# substitute goods or services; loss of use, data, or profits; or business
# interruption) however caused and on any theory of liability, whether in
# contract, strict liability, or tort (including negligence or otherwise)
# arising in any way out of the use of this software, even if advised of the
# possibility of such damage.
###

###
# Risk of Rain
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20180529.1

# Set game-specific variables

GAME_ID='risk-of-rain'
GAME_NAME='Risk of Rain'

ARCHIVES_LIST='ARCHIVE_GOG ARCHIVE_HUMBLE'

ARCHIVE_GOG='gog_risk_of_rain_2.1.0.5.sh'
ARCHIVE_GOG_URL='https://www.gog.com/game/risk_of_rain'
ARCHIVE_GOG_MD5='34f8e1e2dddc6726a18c50b27c717468'
ARCHIVE_GOG_SIZE='180000'
ARCHIVE_GOG_VERSION='1.2.8-gog2.1.0.5'

ARCHIVE_HUMBLE='Risk_of_Rain_v1.3.0_DRM-Free_Linux_.zip'
ARCHIVE_HUMBLE_URL='https://www.humblebundle.com/store/risk-of-rain'
ARCHIVE_HUMBLE_MD5='21eb80a7b517d302478c4f86dd5ea9a2'
ARCHIVE_HUMBLE_SIZE='100000'
ARCHIVE_HUMBLE_VERSION='1.3.0-humble160519'

ARCHIVE_LIBSSL_32='libssl_1.0.0_32-bit.tar.gz'
ARCHIVE_LIBSSL_32_MD5='9443cad4a640b2512920495eaf7582c4'

ARCHIVE_LIBCURL3_32='libcurl3_7.60.0_32-bit.tar.gz'
ARCHIVE_LIBCURL3_32_MD5='7206100f065d52de5a4c0b49644aa052'

ARCHIVE_DOC_PATH_GOG='data/noarch/docs'
ARCHIVE_DOC_FILES_GOG='./*'

ARCHIVE_GAME_BIN_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_BIN_PATH_HUMBLE='.'
ARCHIVE_GAME_BIN_FILES='./Risk_of_Rain'

ARCHIVE_GAME_DATA_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_DATA_PATH_HUMBLE='.'
ARCHIVE_GAME_DATA_FILES='./assets'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='Risk_of_Rain'
APP_MAIN_ICON='assets/icon.png'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS="$PKG_DATA_ID glibc libstdc++ glu openal libxrandr libcurl"
PKG_BIN_DEPS_ARCH='lib32-openssl-1.0'

# Load common functions

target_version='2.9'

if [ -z "$PLAYIT_LIB2" ]; then
	[ -n "$XDG_DATA_HOME" ] || XDG_DATA_HOME="$HOME/.local/share"
	for path in\
		'./'\
		"$XDG_DATA_HOME/play.it/"\
		"$XDG_DATA_HOME/play.it/play.it-2/lib/"\
		'/usr/local/share/games/play.it/'\
		'/usr/local/share/play.it/'\
		'/usr/share/games/play.it/'\
		'/usr/share/play.it/'
	do
		if [ -z "$PLAYIT_LIB2" ] && [ -e "$path/libplayit2.sh" ]; then
			PLAYIT_LIB2="$path/libplayit2.sh"
			break
		fi
	done
	if [ -z "$PLAYIT_LIB2" ]; then
		printf '\n\033[1;31mError:\033[0m\n'
		printf 'libplayit2.sh not found.\n'
		return 1
	fi
fi
. "$PLAYIT_LIB2"

# Use libSSL 1.0.0 32-bit archive

if [ "$OPTION_PACKAGE" != 'arch' ]; then
	ARCHIVE_MAIN="$ARCHIVE"
	archive_set 'ARCHIVE_LIBSSL' 'ARCHIVE_LIBSSL_32'
	ARCHIVE="$ARCHIVE_MAIN"
fi

# Use libcurl 3 32-bit archive

ARCHIVE_MAIN="$ARCHIVE"
archive_set 'ARCHIVE_LIBCURL' 'ARCHIVE_LIBCURL3_32'
ARCHIVE="$ARCHIVE_MAIN"

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"
prepare_package_layout
rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Include libSSL into the game directory

if [ "$ARCHIVE_LIBSSL" ]; then
	(
		ARCHIVE='ARCHIVE_LIBSSL'
		extract_data_from "$ARCHIVE_LIBSSL"
	)
	dir="$APP_MAIN_LIBS"
	[ -n "$dir" ] || dir='libs'
	APP_MAIN_LIBS="$dir"
	mkdir --parents "${PKG_BIN_PATH}${PATH_GAME}/$dir"
	mv "$PLAYIT_WORKDIR/gamedata"/* "${PKG_BIN_PATH}${PATH_GAME}/$dir"
	APP_MAIN_LIBS="$dir"
	rm --recursive "$PLAYIT_WORKDIR/gamedata"
fi

# Include libcurl into the game directory

if [ "$ARCHIVE_LIBCURL" ]; then
	(
		ARCHIVE='ARCHIVE_LIBCURL'
		extract_data_from "$ARCHIVE_LIBCURL"
	)
	dir="$APP_MAIN_LIBS"
	[ -n "$dir" ] || dir='libs'
	APP_MAIN_LIBS="$dir"
	mkdir --parents "${PKG_BIN_PATH}${PATH_GAME}/$dir"
	mv "$PLAYIT_WORKDIR/gamedata"/* "${PKG_BIN_PATH}${PATH_GAME}/$dir"
	rm --recursive "$PLAYIT_WORKDIR/gamedata"
fi

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

PKG='PKG_DATA'
icons_linking_postinst 'APP_MAIN'
write_metadata 'PKG_DATA'

cat > "$postinst" << EOF
if [ -e "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.4.5.0" ]; then
	if [ ! -e "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.4" ]; then
		ln --symbolic 'libcurl.so.4.5.0' "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.4"
	fi
	if [ ! -e "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.3" ]; then
		ln --symbolic 'libcurl.so.4.5.0' "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.3"
	fi
fi
EOF

cat > "$prerm" << EOF
if [ -e "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.4" ]; then
	rm "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.4"
fi
if [ -e "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.3" ]; then
	rm "$PATH_GAME/$APP_MAIN_LIBS/libcurl.so.3"
fi
EOF

write_metadata 'PKG_BIN'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
