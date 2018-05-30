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
# The Witcher 2
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20180530.1

# Set game-specific variables

GAME_ID='the-witcher-2'
GAME_NAME='The Witcher 2: Assassins Of Kings'

ARCHIVE_GOG='the_witcher_2_assassins_of_kings_enhanced_edition_en_release_3_20150306204412_20992.sh'
ARCHIVE_GOG_URL='https://www.gog.com/game/the_witcher_2'
ARCHIVE_GOG_MD5='fd7b85d44e3da7fdf860ab4267574b36'
ARCHIVE_GOG_SIZE='24000000'
ARCHIVE_GOG_VERSION='1release3-gog20992'
ARCHIVE_GOG_TYPE='mojosetup_unzip'

ARCHIVE_GOG_OLD='gog_the_witcher_2_assassins_of_kings_enhanced_edition_2.2.0.8.sh'
ARCHIVE_GOG_OLD_MD5='3fff5123677a7be2023ecdb6af3b82b6'
ARCHIVE_GOG_OLD_SIZE='24000000'
ARCHIVE_GOG_OLD_VERSION='1release3-gog2.2.0.8'
ARCHIVE_GOG_OLD_TYPE='mojosetup_unzip'

ARCHIVE_DOC0_DATA_PATH='data/noarch/docs'
ARCHIVE_DOC0_DATA_FILES='./*'

ARCHIVE_DOC1_DATA_PATH='data/noarch/game'
ARCHIVE_DOC1_DATA_FILES='./*.rtf ./*.txt'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='./bin ./configurator ./CrashReporter* ./crash_reporting ./eONprecompiledShaders32.dat ./*launcher* ./libopenal-eon.so.1 ./saferun.sh ./sdlinput ./witcher2'

ARCHIVE_GAME_PACK1_PATH='data/noarch/game'
ARCHIVE_GAME_PACK1_FILES='./CookedPC/pack0.dzip.split00'

ARCHIVE_GAME_PACK2_PATH='data/noarch/game'
ARCHIVE_GAME_PACK2_FILES='./CookedPC/pack0.dzip.split01 ./CookedPC/pack0.dzip.split02'

ARCHIVE_GAME_MOVIES_PATH='data/noarch/game'
ARCHIVE_GAME_MOVIES_FILES='./CookedPC/movies'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./CookedPC ./fontconfig ./icudt52l.dat ./linux ./SDLGamepad.config ./VPFS_registry.vpfsdb ./witcher2.vpfs'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='witcher2'
APP_MAIN_ICON='linux/icons/witcher2-icon.png'

APP_CONFIG_ID="${GAME_ID}_config"
APP_CONFIG_TYPE='native'
APP_CONFIG_EXE='configurator'
APP_CONFIG_NAME="$GAME_NAME - configuration"
APP_CONFIG_ICON='linux/icons/witcher2-configurator.png'
APP_CONFIG_CAT='Settings'

PACKAGES_LIST='PKG_BIN PKG_PACK1 PKG_PACK2 PKG_MOVIES PKG_DATA'

PKG_PACK1_ID="${GAME_ID}-pack1"
PKG_PACK1_DESCRIPTION='pack0, part 1'

PKG_PACK2_ID="${GAME_ID}-pack2"
PKG_PACK2_DESCRIPTION='pack0, part 2'

PKG_MOVIES_ID="${GAME_ID}-movies"
PKG_MOVIES_DESCRIPTION='movies'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS="$PKG_PACK1_ID $PKG_PACK2_ID $PKG_MOVIES_ID $PKG_DATA_ID alsa gtk2 sdl2_image freetype libcurl"
PKG_BIN_DEPS_DEB='libtxc-dxtn-s2tc0 | libtxc-dxtn0, libudev1'
PKG_BIN_DEPS_ARCH='lib32-libtxc_dxtn'

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

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"
prepare_package_layout
rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN' 'APP_CONFIG'

# Build package

PKG='PKG_DATA'
postinst_icons_linking 'APP_MAIN' 'APP_CONFIG'
write_metadata 'PKG_DATA'

cat > "$postinst" << EOF
printf 'Building pack0.dzip, this might take a while…\n'
cat "$PATH_GAME/CookedPC/pack0.dzip.split"* > "$PATH_GAME/CookedPC/pack0.dzip"
rm "$PATH_GAME/CookedPC/pack0.dzip.split"*
EOF
cat > "$prerm" << EOF
rm "$PATH_GAME/CookedPC/pack0.dzip"
EOF
write_metadata 'PKG_BIN'

write_metadata 'PKG_PACK1' 'PKG_PACK2' 'PKG_MOVIES'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
