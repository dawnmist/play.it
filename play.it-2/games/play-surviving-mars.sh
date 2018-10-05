#!/bin/sh -e
set -o errexit

###
# Copyright (c) 2015-2018, Antoine Le Gonidec
# Copyright (c) 2018, Janeene Beeforth
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
# Surviving Mars
# build native packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20181005.1

# Set game-specific variables

GAME_ID='surviving-mars'
GAME_NAME='Surviving Mars'

ARCHIVE_GOG='surviving_mars_sagan_rc3_update_24111.sh'
ARCHIVE_GOG_MD5='22e5cbc7188ff1cb8fd5dabf7cdca0bf'
ARCHIVE_GOG_SIZE='4700000'
ARCHIVE_GOG_VERSION='235.636-rc3-gog24111'
ARCHIVE_GOG_TYPE='mojosetup_unzip'
ARCHIVE_GOG_URL='https://www.gog.com/game/surviving_mars'

ARCHIVE_GOG_OLD3='surviving_mars_sagan_rc1_update_23676.sh'
ARCHIVE_GOG_OLD3_MD5='2e5058a9f1076f894c0b074fd24e3597'
ARCHIVE_GOG_OLD3_SIZE='4700000'
ARCHIVE_GOG_OLD3_VERSION='234.560-rc1-gog23676'
ARCHIVE_GOG_OLD3_TYPE='mojosetup_unzip'

ARCHIVE_GOG_OLD2='surviving_mars_en_davinci_rc1_22763.sh'
ARCHIVE_GOG_OLD2_MD5='aa513fee4b4c10318831712d4663bfc0'
ARCHIVE_GOG_OLD2_SIZE='4400000'
ARCHIVE_GOG_OLD2_VERSION='233.467-rc1-gog22763'
ARCHIVE_GOG_OLD2_TYPE='mojosetup_unzip'

ARCHIVE_GOG_OLD1='surviving_mars_en_180619_curiosity_hotfix_3_21661.sh'
ARCHIVE_GOG_OLD1_MD5='241f1cb8305becab5d55c8d104bd2c18'
ARCHIVE_GOG_OLD1_SIZE='4100000'
ARCHIVE_GOG_OLD1_VERSION='231.777-3-gog21661'
ARCHIVE_GOG_OLD1_TYPE='mojosetup_unzip'

ARCHIVE_GOG_OLD0='surviving_mars_en_curiosity_update_21183.sh'
ARCHIVE_GOG_OLD0_MD5='ab9a61d04a128f19bc9e003214fe39a9'
ARCHIVE_GOG_OLD0_VERSION='231.139'
ARCHIVE_GOG_OLD0_SIZE='3950000'
ARCHIVE_GOG_OLD0_TYPE='mojosetup_unzip'

ARCHIVE_OPTIONAL_LIBSSL64='libssl_1.0.0_64-bit.tar.gz'
ARCHIVE_OPTIONAL_LIBSSL64_MD5='89917bef5dd34a2865cb63c2287e0bd4'

ARCHIVE_DOC_DATA_PATH='data/noarch/docs'
ARCHIVE_DOC_DATA_FILES='*'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='MarsGOG libopenal.so.1 libSDL2-2.0.so.0 libpops_api.so pops_api.dll'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='DLC Licenses Local ModTools Movies Packs ShaderPreprocessorTemp'

APP_MAIN_TYPE='native'
APP_MAIN_LIBS='libs'
APP_MAIN_EXE='MarsGOG'
APP_MAIN_ICON='data/noarch/support/icon.png'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_BIN_ARCH='64'
PKG_BIN_DEPS="$PKG_DATA_ID glibc libstdc++ glx"
PKG_BIN_DEPS_ARCH='openssl-1.0'

# Load common functions

target_version='2.10'

if [ -z "$PLAYIT_LIB2" ]; then
	: ${XDG_DATA_HOME:="$HOME/.local/share"}
	for path in\
		"$PWD"\
		"$XDG_DATA_HOME/play.it"\
		'/usr/local/share/games/play.it'\
		'/usr/local/share/play.it'\
		'/usr/share/games/play.it'\
		'/usr/share/play.it'
	do
		if [ -e "$path/libplayit2.sh" ]; then
			PLAYIT_LIB2="$path/libplayit2.sh"
			break
		fi
	done
fi
if [ -z "$PLAYIT_LIB2" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'libplayit2.sh not found.\n'
	exit 1
fi
. "$PLAYIT_LIB2"

# Use libSSL 1.0.0 64-bit archive (Debian packages only)

if [ "$OPTION_PACKAGE" = 'deb' ]; then
	ARCHIVE_MAIN="$ARCHIVE"
	set_archive 'ARCHIVE_LIBSSL64' 'ARCHIVE_OPTIONAL_LIBSSL64'
	ARCHIVE="$ARCHIVE_MAIN"
fi

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"
prepare_package_layout

# Get icon

PKG='PKG_DATA'
icons_get_from_workdir 'APP_MAIN'
rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Include libSSL 1.0.0 64-bit (Debian packages only)

if [ "$ARCHIVE_LIBSSL64" ]; then
	(
		ARCHIVE='ARCHIVE_LIBSSL64'
		extract_data_from "$ARCHIVE_LIBSSL64"
	)
	mkdir --parents "${PKG_BIN_PATH}${PATH_GAME}/$APP_MAIN_LIBS"
	mv "$PLAYIT_WORKDIR/gamedata"/* "${PKG_BIN_PATH}${PATH_GAME}/$APP_MAIN_LIBS"
	rm --recursive "$PLAYIT_WORKDIR/gamedata"
fi

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
