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
# Digital Deluxe Upgrade for Surviving Mars.
# build native packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20181005.1

# Set game-specific variables

# copy GAME_ID from play-surviving-mars.sh
GAME_ID='surviving-mars'
GAME_NAME='Surviving Mars: Digital Deluxe Upgrade'

ARCHIVE_GOG='surviving_mars_digital_deluxe_edition_upgrade_pack_sagan_rc3_update_24111.sh'
ARCHIVE_GOG_MD5='60cddca455eb1882e0ca7ebf4e26838a'
ARCHIVE_GOG_SIZE='66000'
ARCHIVE_GOG_VERSION='24111'
ARCHIVE_GOG_TYPE='mojosetup_unzip'
ARCHIVE_GOG_URL='https://www.gog.com/game/surviving_mars_digital_deluxe_edition_upgrade_pack'

ARCHIVE_GOG_OLD3='surviving_mars_digital_deluxe_edition_upgrade_pack_sagan_rc1_update_23676.sh'
ARCHIVE_GOG_OLD3_MD5='7ba5d3ab5626f1a18015b9516adf29af'
ARCHIVE_GOG_OLD3_SIZE='66000'
ARCHIVE_GOG_OLD3_VERSION='23676'
ARCHIVE_GOG_OLD3_TYPE='mojosetup_unzip'

ARCHIVE_GOG_OLD2='surviving_mars_digital_deluxe_edition_upgrade_pack_en_davinci_rc1_22763.sh'
ARCHIVE_GOG_OLD2_MD5='195f0d1a28047112ced2d9cc31df5e52'
ARCHIVE_GOG_OLD2_SIZE='67000'
# Switching to the build number directly in future
ARCHIVE_GOG_OLD2_VERSION='22763'
ARCHIVE_GOG_OLD2_TYPE='mojosetup_unzip'

ARCHIVE_GOG_OLD1='surviving_mars_digital_deluxe_edition_upgrade_pack_en_180619_curiosity_hotfix_3_21661.sh'
ARCHIVE_GOG_OLD1_MD5='cef24bda9587c1923139ea0c86df317a'
ARCHIVE_GOG_OLD1_SIZE='66000'
ARCHIVE_GOG_OLD1_VERSION='3-gog21661'
ARCHIVE_GOG_OLD1_TYPE='mojosetup_unzip'

ARCHIVE_GOG_OLD0='surviving_mars_digital_deluxe_edition_upgrade_pack_en_180423_opportunity_rc1_20289.sh'
ARCHIVE_GOG_OLD0_MD5='a574de12f4b7f3aa1f285167109bb6a3'
ARCHIVE_GOG_OLD0_SIZE="66000"
ARCHIVE_GOG_OLD0_VERSION="1-gog20289"
ARCHIVE_GOG_OLD0_TYPE='mojosetup_unzip'

ARCHIVE_DOC_MAIN_PATH='data/noarch/docs'
ARCHIVE_DOC_MAIN_FILES='*'

ARCHIVE_GAME_MAIN_PATH='data/noarch/game'
ARCHIVE_GAME_MAIN_FILES='DLC'

PACKAGES_LIST='PKG_MAIN'

PKG_MAIN_ID="${GAME_ID}-digital-deluxe-upgrade-pack"
PKG_MAIN_DEPS="$GAME_ID"

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

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"
prepare_package_layout
rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
