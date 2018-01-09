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
# Deus Ex
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20171108.2

# Set game-specific variables

GAME_ID='deus-ex'
GAME_NAME='Deus Ex'

ARCHIVES_LIST='ARCHIVE_GOG ARCHIVE_GOG_OLD'

ARCHIVE_GOG='setup_deus_ex_goty_1.112fm(revision_1.3.0.1)_(16231).exe'
ARCHIVE_GOG_MD5='eaaf7c7c3052fbf71f5226e2d4495268'
ARCHIVE_GOG_VERSION='1.112fm-gog16231'
ARCHIVE_GOG_SIZE='750000'

ARCHIVE_GOG_OLD='setup_deus_ex_goty_1.112fm(revision_1.2.2)_(15442).exe'
ARCHIVE_GOG_OLD_MD5='573582142424ba1b5aba1f6727276450'
ARCHIVE_GOG_OLD_VERSION='1.112fm-gog15442'
ARCHIVE_GOG_OLD_SIZE='750000'

ARCHIVE_DOC_DATA_PATH='app'
ARCHIVE_DOC_DATA_FILES='./manual.pdf ./system/*.txt'

ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./system/*.exe ./system/*.ini ./system/*.int ./system/3dfxspl2.dll ./system/3dfxspl3.dll ./system/3dfxspl.dll ./system/consys.dll ./system/core.dll ./system/d3ddrv.dll ./system/deusex.dll ./system/deusextext.dll ./system/editor.dll ./system/engine.dll ./system/extension.dll ./system/fire.dll ./system/galaxy.dll ./system/glide2x.dll ./system/glide3x.dll ./system/glide.dll ./system/glidedrv.dll ./system/ipdrv.dll ./system/metaldrv.dll ./system/msvcrt.dll ./system/opengldrv.dll ./system/render.dll ./system/sgldrv.dll ./system/softdrv.dll ./system/window.dll ./system/windrv.dll'

ARCHIVE_GAME_DATA_PATH='app'
ARCHIVE_GAME_DATA_FILES='./system/*.u ./help ./maps ./music ./sounds ./textures'

CONFIG_FILES='./system/*.ini'
DATA_DIRS='./save'
DATA_FILES='./system/*.log'

APP_MAIN_TYPE='wine'
APP_MAIN_PRERUN="rgamma=\$(xgamma 2>&1|sed 's/->//'|cut -d',' -f1|awk '{print \$2}')
ggamma=\$(xgamma 2>&1|sed 's/->//'|cut -d',' -f2|awk '{print \$2}')
bgamma=\$(xgamma 2>&1|sed 's/->//'|cut -d',' -f3|awk '{print \$2}')"
APP_MAIN_POSTRUN='xgamma -rgamma $rgamma -ggamma $ggamma -bgamma $bgamma' # Works only with library version >= 2.2
APP_MAIN_EXE='system/deusex.exe'
APP_MAIN_ICON='system/deusex.exe'
APP_MAIN_ICON_RES='16 32'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, wine32-development | wine32 | wine-bin | wine-i386 | wine-staging-i386, wine:amd64 | wine, x11-xserver-utils:amd64 | x11-xserver-utils"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID wine xorg-xgamma"

# Load common functions

target_version='2.1'

if [ -z "$PLAYIT_LIB2" ]; then
	[ -n "$XDG_DATA_HOME" ] || XDG_DATA_HOME="$HOME/.local/share"
	if [ -e "$XDG_DATA_HOME/play.it/play.it-2/lib/libplayit2.sh" ]; then
		PLAYIT_LIB2="$XDG_DATA_HOME/play.it/play.it-2/lib/libplayit2.sh"
	elif [ -e './libplayit2.sh' ]; then
		PLAYIT_LIB2='./libplayit2.sh'
	else
		printf '\n\033[1;31mError:\033[0m\n'
		printf 'libplayit2.sh not found.\n'
		return 1
	fi
fi
. "$PLAYIT_LIB2"

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"

for PKG in 'PKG_DATA' 'PKG_BIN'; do
	organize_data "DOC_${PKG#PKG_}"  "$PATH_DOC"
	organize_data "GAME_${PKG#PKG_}" "$PATH_GAME"
done

PKG='PKG_BIN'
extract_and_sort_icons_from 'APP_MAIN'
move_icons_to 'PKG_DATA'

rm --recursive "$PLAYIT_WORKDIR/gamedata"

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