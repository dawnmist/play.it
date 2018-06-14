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
# common functions for ./play.it scripts
# send your bug reports to vv221@dotslashplay.it
###

library_version=2.9.0
library_revision=20180610.1

# set package distribution-specific architecture
# USAGE: set_architecture $pkg
# CALLS: liberror set_architecture_arch set_architecture_deb
# NEEDED VARS: (ARCHIVE) (OPTION_PACKAGE) (PKG_ARCH)
# CALLED BY: set_temp_directories write_metadata
set_architecture() {
	use_archive_specific_value "${1}_ARCH"
	local architecture
	architecture="$(eval printf -- '%b' \"\$${1}_ARCH\")"
	case $OPTION_PACKAGE in
		('arch')
			set_architecture_arch "$architecture"
		;;
		('deb')
			set_architecture_deb "$architecture"
		;;
		(*)
			liberror 'OPTION_PACKAGE' 'set_architecture'
		;;
	esac
}

# test the validity of the argument given to parent function
# USAGE: testvar $var_name $pattern
testvar() {
	test "${1%%_*}" = "$2"
}

# set defaults rights on files (755 for dirs & 644 for regular files)
# USAGE: set_standard_permissions $dir[…]
set_standard_permissions() {
	[ "$DRY_RUN" = '1' ] && return 0
	for dir in "$@"; do
		[  -d "$dir" ] || return 1
		find "$dir" -type d -exec chmod 755 '{}' +
		find "$dir" -type f -exec chmod 644 '{}' +
	done
}

# print OK
# USAGE: print_ok
print_ok() {
	printf '\t\033[1;32mOK\033[0m\n'
}

# print a localized error message
# USAGE: print_error
# NEEDED VARS: (LANG)
print_error() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Erreur :'
		;;
		('en'|*)
			string='Error:'
		;;
	esac
	printf '\n\033[1;31m%s\033[0m\n' "$string"
	exec 1>&2
}

# print a localized warning message
# USAGE: print_warning
# NEEDED VARS: (LANG)
print_warning() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Avertissement :'
		;;
		('en'|*)
			string='Warning:'
		;;
	esac
	printf '\n\033[1;33m%s\033[0m\n' "$string"
}

# convert files name to lower case
# USAGE: tolower $dir[…]
tolower() {
	[ "$DRY_RUN" = '1' ] && return 0
	for dir in "$@"; do
		[ -d "$dir" ] || return 1
		find "$dir" -depth -mindepth 1 | while read -r file; do
			newfile="${file%/*}/$(printf '%s' "${file##*/}" | tr '[:upper:]' '[:lower:]')"
			[ -e "$newfile" ] || mv "$file" "$newfile"
		done
	done
}

# display an error if a function has been called with invalid arguments
# USAGE: liberror $var_name $calling_function
# NEEDED VARS: (LANG)
liberror() {
	local var
	var="$1"
	local value
	value="$(eval printf -- '%b' \"\$$var\")"
	local func
	func="$2"
	print_error
	case "${LANG%_*}" in
		('fr')
			string='Valeur incorrecte pour %s appelée par %s : %s\n'
		;;
		('en'|*)
			string='Invalid value for %s called by %s: %s\n'
		;;
	esac
	printf "$string" "$var" "$func" "$value"
	return 1
}

# get archive-specific value for a given variable name, or use default value
# USAGE: use_archive_specific_value $var_name
use_archive_specific_value() {
	[ -n "$ARCHIVE" ] || return 0
	testvar "$ARCHIVE" 'ARCHIVE' || liberror 'ARCHIVE' 'use_archive_specific_value'
	local name_real
	name_real="$1"
	local name
	name="${name_real}_${ARCHIVE#ARCHIVE_}"
	local value
	while [ "$name" != "$name_real" ]; do
		value="$(eval printf -- '%b' \"\$$name\")"
		if [ -n "$value" ]; then
			eval $name_real=\"$value\"
			export $name_real
			return 0
		fi
		name="${name%_*}"
	done
}

# get package-specific value for a given variable name, or use default value
# USAGE: use_package_specific_value $var_name
use_package_specific_value() {
	[ -n "$PKG" ] || return 0
	testvar "$PKG" 'PKG' || liberror 'PKG' 'use_package_specific_value'
	local name_real
	name_real="$1"
	local name
	name="${name_real}_${PKG#PKG_}"
	local value
	while [ "$name" != "$name_real" ]; do
		value="$(eval printf -- '%b' \"\$$name\")"
		if [ -n "$value" ]; then
			eval $name_real=\"$value\"
			export $name_real
			return 0
		fi
		name="${name%_*}"
	done
}

# display an error when PKG value seems invalid
# USAGE: missing_pkg_error $function_name $PKG
# NEEDED VARS: (LANG)
missing_pkg_error() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='La valeur de PKG fournie à %s semble incorrecte : %s\n'
		;;
		('en'|*)
			string='The PKG value used by %s seems erroneous: %s\n'
		;;
	esac
	printf "$string" "$1" "$2"
	exit 1
}

# display a warning when PKG value is not included in PACKAGES_LIST
# USAGE: skipping_pkg_warning $function_name $PKG
# NEEDED VARS: (LANG)
skipping_pkg_warning() {
	local string
	print_warning
	case "${LANG%_*}" in
		('fr')
			string='La valeur de PKG fournie à %s ne fait pas partie de la liste de paquets à construire : %s\n'
		;;
		('en'|*)
			string='The PKG value used by %s is not part of the list of packages to build: %s\n'
		;;
	esac
	printf "$string" "$1" "$2"
}

# set distribution-specific package architecture for Arch Linux target
# USAGE: set_architecture_arch $architecture
# CALLED BY: set_architecture
set_architecture_arch() {
	case "$1" in
		('32'|'64')
			pkg_architecture='x86_64'
		;;
		(*)
			pkg_architecture='any'
		;;
	esac
}

# set distribution-specific package architecture for Debian target
# USAGE: set_architecture_deb $architecture
# CALLED BY: set_architecture
set_architecture_deb() {
	case "$1" in
		('32')
			pkg_architecture='i386'
		;;
		('64')
			pkg_architecture='amd64'
		;;
		(*)
			pkg_architecture='all'
		;;
	esac
}

# set main archive for data extraction
# USAGE: archive_set_main $archive[…]
# CALLS: archive_set archive_set_error_not_found
archive_set_main() {
	archive_set 'SOURCE_ARCHIVE' "$@"
	[ -n "$SOURCE_ARCHIVE" ] || archive_set_error_not_found "$@"
}

# display an error message if a required archive is not found
# list all the archives that could fulfill the requirements, with their download URL if provided by the script
# USAGE: archive_set_error_not_found $archive[…]
# CALLED BY: archive_set_main
archive_set_error_not_found() {
	local archive
	local archive_name
	local archive_url
	local string
	local string_multiple
	local string_single
	case "${LANG%_*}" in
		('fr')
			string_multiple='Aucun des fichiers suivants n’est présent :'
			string_single='Le fichier suivant est introuvable :'
		;;
		('en'|*)
			string_multiple='None of the following files could be found:'
			string_single='The following file could not be found:'
		;;
	esac
	if [ "$#" = 1 ]; then
		string="$string_single"
	else
		string="$string_multiple"
	fi
	print_error
	printf '%s\n' "$string"
	for archive in "$@"; do
		archive_name="$(eval printf -- '%b' \"\$$archive\")"
		archive_url="$(eval printf -- '%b' \"\$${archive}_URL\")"
		printf '%s' "$archive_name"
		[ -n "$archive_url" ] && printf ' — %s' "$archive_url"
		printf '\n'
	done
	return 1
}
# compatibility alias
set_archive_error_not_found() { archive_set_error_not_found "$@"; }

# set a single archive for data extraction
# USAGE: archive_set $name $archive[…]
# CALLS: archive_get_infos archive_check_for_extra_parts
archive_set() {
	local archive
	local current_value
	local file
	local name
	name=$1
	shift 1
	current_value="$(eval printf -- '%b' \"\$$name\")"
	if [ -n "$current_value" ]; then
		for archive in "$@"; do
			file="$(eval printf -- '%b' \"\$$archive\")"
			if [ "$(basename "$current_value")" = "$file" ]; then
				archive_get_infos "$archive" "$name" "$current_value"
				archive_check_for_extra_parts "$archive" "$name"
				ARCHIVE="$archive"
				export ARCHIVE
				return 0
			fi
		done
	else
		for archive in "$@"; do
			file="$(eval printf -- '%b' \"\$$archive\")"
			if [ ! -f "$file" ] && [ -n "$SOURCE_ARCHIVE" ] && [ -f "${SOURCE_ARCHIVE%/*}/$file" ]; then
				file="${SOURCE_ARCHIVE%/*}/$file"
			fi
			if [ -f "$file" ]; then
				archive_get_infos "$archive" "$name" "$file"
				archive_check_for_extra_parts "$archive" "$name"
				ARCHIVE="$archive"
				export ARCHIVE
				return 0
			fi
		done
	fi
	unset $name
}
# compatibility alias
set_archive() { archive_set "$@"; }

# automatically check for presence of archives using the name of the base archive with a _PART1 to _PART9 suffix appended
# returns an error if such an archive is set by the script but not found
# returns success on the first archive not set by the script
# USAGE: archive_check_for_extra_parts $archive $name
# NEEDED_VARS: (LANG) (SOURCE_ARCHIVE)
# CALLS: set_archive
archive_check_for_extra_parts() {
	local archive
	local file
	local name
	local part_archive
	local part_name
	archive="$1"
	name="$2"
	for i in $(seq 1 9); do
		part_archive="${archive}_PART${i}"
		part_name="${name}_PART${i}"
		file="$(eval printf -- '%b' \"\$$part_archive\")"
		[ -n "$file" ] || return 0
		set_archive "$part_name" "$part_archive"
		if [ -z "$(eval printf -- '%b' \"\$$part_name\")" ]; then
			set_archive_error_not_found "$part_archive"
		fi
	done
}

# get informations about a single archive and export them
# USAGE: archive_get_infos $archive $name $file
# CALLS: archive_guess_type archive_integrity_check archive_print_file_in_use check_deps
# CALLED BY: archive_set
archive_get_infos() {
	local file
	local md5
	local name
	local size
	local type
	ARCHIVE="$1"
	name="$2"
	file="$3"
	archive_print_file_in_use "$file"
	eval $name=\"$file\"
	md5="$(eval printf -- '%b' \"\$${ARCHIVE}_MD5\")"
	type="$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")"
	size="$(eval printf -- '%b' \"\$${ARCHIVE}_SIZE\")"
	[ -n "$md5" ] && archive_integrity_check "$ARCHIVE" "$file"
	if [ -z "$type" ]; then
		archive_guess_type "$ARCHIVE" "$file"
		type="$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")"
	fi
	eval ${name}_TYPE=\"$type\"
	export ${name}_TYPE
	check_deps
	if [ -n "$size" ]; then
		[ -n "$ARCHIVE_SIZE" ] || ARCHIVE_SIZE='0'
		ARCHIVE_SIZE="$((ARCHIVE_SIZE + size))"
	fi
	export ARCHIVE_SIZE
	export PKG_VERSION
	export $name
	export ARCHIVE
}

# try to guess archive type from file name
# USAGE: archive_guess_type $archive $file
# CALLS: archive_guess_type_error
# CALLED BY: archive_get_infos
archive_guess_type() {
	local archive
	local file
	local type
	archive="$1"
	file="$2"
	case "${file##*/}" in
		(*'.cab')
			type='cabinet'
		;;
		(*'.deb')
			type='debian'
		;;
		('setup_'*'.exe'|'patch_'*'.exe')
			type='innosetup'
		;;
		('gog_'*'.sh')
			type='mojosetup'
		;;
		(*'.msi')
			type='msi'
		;;
		(*'.rar')
			type='rar'
		;;
		(*'.tar')
			type='tar'
		;;
		(*'.tar.gz'|*'.tgz')
			type='tar.gz'
		;;
		(*'.zip')
			type='zip'
		;;
		(*)
			archive_guess_type_error "$archive"
		;;
	esac
	eval ${archive}_TYPE=\'$type\'
	export ${archive}_TYPE
}

# display an error message if archive_guess_type failed to guess the type of an archive
# USAGE: archive_guess_type_error $archive
# CALLED BY: archive_guess_type
archive_guess_type_error() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='ARCHIVE_TYPE n’est pas défini pour %s et n’a pas pu être détecté automatiquement.'
		;;
		('en'|*)
			string='ARCHIVE_TYPE is not set for %s and could not be guessed.'
		;;
	esac
	print_error
	printf "$string\\n" "$archive"
	return 1
}

# print the name and path to the archive currently in use
# USAGE: archive_print_file_in_use $file
# CALLED BY: archive_get_infos
archive_print_file_in_use() {
	local file
	local string
	file="$1"
	case "${LANG%_*}" in
		('fr')
			string='Utilisation de %s'
		;;
		('en'|*)
			string='Using %s'
		;;
	esac
	printf "$string\\n" "$file"
}

# check integrity of target file
# USAGE: archive_integrity_check $archive $file
# CALLS: archive_integrity_check_md5 liberror
archive_integrity_check() {
	local archive
	local file
	archive="$1"
	file="$2"
	case "$OPTION_CHECKSUM" in
		('md5')
			archive_integrity_check_md5 "$archive" "$file"
			print_ok
		;;
		('none')
			return 0
		;;
		(*)
			liberror 'OPTION_CHECKSUM' 'archive_integrity_check'
		;;
	esac
}

# check integrity of target file against MD5 control sum
# USAGE: archive_integrity_check_md5 $archive $file
# CALLS: archive_integrity_check_print archive_integrity_check_error
# CALLED BY: archive_integrity_check
archive_integrity_check_md5() {
	local archive
	local file
	archive="$1"
	file="$2"
	archive_integrity_check_print "$file"
	archive_sum="$(eval printf -- '%b' \"\$${ARCHIVE}_MD5\")"
	file_sum="$(md5sum "$file" | awk '{print $1}')"
	[ "$file_sum" = "$archive_sum" ] || archive_integrity_check_error "$file"
}

# print integrity check message
# USAGE: archive_integrity_check_print $file
# CALLED BY: archive_integrity_check_md5
archive_integrity_check_print() {
	local file
	local string
	file="$1"
	case "${LANG%_*}" in
		('fr')
			string='Contrôle de l’intégrité de %s'
		;;
		('en'|*)
			string='Checking integrity of %s'
		;;
	esac
	printf "$string" "$(basename "$file")"
}

# print an error message if an integrity check fails
# USAGE: archive_integrity_check_error $file
# CALLED BY: archive_integrity_check_md5
archive_integrity_check_error() {
	local string1
	local string2
	case "${LANG%_*}" in
		('fr')
			string1='Somme de contrôle incohérente. %s n’est pas le fichier attendu.'
			string2='Utilisez --checksum=none pour forcer son utilisation.'
		;;
		('en'|*)
			string1='Hashsum mismatch. %s is not the expected file.'
			string2='Use --checksum=none to force its use.'
		;;
	esac
	print_error
	printf "$string1\\n" "$(basename "$1")"
	printf "$string2\\n"
	return 1
}

# get list of available archives, exported as ARCHIVES_LIST
# USAGE: archives_get_list
archives_get_list() {
	local script
	[ -n "$ARCHIVES_LIST" ] && return 0
	script="$0"
	while read archive; do
		if [ -z "$ARCHIVES_LIST" ]; then
			ARCHIVES_LIST="$archive"
		else
			ARCHIVES_LIST="$ARCHIVES_LIST $archive"
		fi
	done <<- EOL
	$(grep --regexp='^ARCHIVE_[^_]\+=' --regexp='^ARCHIVE_[^_]\+_OLD=' --regexp='^ARCHIVE_[^_]\+_OLD[^_]\+=' "$script" | sed 's/\([^=]\)=.\+/\1/')
	EOL
	export ARCHIVES_LIST
}

# check script dependencies
# USAGE: check_deps
# NEEDED VARS: (ARCHIVE) (ARCHIVE_TYPE) (OPTION_CHECKSUM) (OPTION_PACKAGE) (SCRIPT_DEPS)
# CALLS: check_deps_7z check_deps_error_not_found icons_list_dependencies
check_deps() {
	icons_list_dependencies
	if [ "$ARCHIVE" ]; then
		case "$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")" in
			('cabinet')
				SCRIPT_DEPS="$SCRIPT_DEPS cabextract"
			;;
			('debian')
				SCRIPT_DEPS="$SCRIPT_DEPS dpkg"
			;;
			('innosetup'*)
				SCRIPT_DEPS="$SCRIPT_DEPS innoextract"
			;;
			('nixstaller')
				SCRIPT_DEPS="$SCRIPT_DEPS gzip tar unxz"
			;;
			('msi')
				SCRIPT_DEPS="$SCRIPT_DEPS msiextract"
			;;
			('mojosetup')
				SCRIPT_DEPS="$SCRIPT_DEPS bsdtar"
			;;
			('rar'|'nullsoft-installer')
				SCRIPT_DEPS="$SCRIPT_DEPS unar"
			;;
			('tar')
				SCRIPT_DEPS="$SCRIPT_DEPS tar"
			;;
			('tar.gz')
				SCRIPT_DEPS="$SCRIPT_DEPS gzip tar"
			;;
			('zip'|'zip_unclean'|'mojosetup_unzip')
				SCRIPT_DEPS="$SCRIPT_DEPS unzip"
			;;
		esac
	fi
	if [ "$OPTION_CHECKSUM" = 'md5sum' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS md5sum"
	fi
	if [ "$OPTION_PACKAGE" = 'deb' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS fakeroot dpkg"
	fi
	for dep in $SCRIPT_DEPS; do
		case $dep in
			('7z')
				check_deps_7z
			;;
			(*)
				if ! command -v "$dep" >/dev/null 2>&1; then
					check_deps_error_not_found "$dep"
				fi
			;;
		esac
	done
}

# check presence of a software to handle .7z archives
# USAGE: check_deps_7z
# CALLS: check_deps_error_not_found
# CALLED BY: check_deps
check_deps_7z() {
	if command -v 7zr >/dev/null 2>&1; then
		extract_7z() { 7zr x -o"$2" -y "$1"; }
	elif command -v 7za >/dev/null 2>&1; then
		extract_7z() { 7za x -o"$2" -y "$1"; }
	elif command -v unar >/dev/null 2>&1; then
		extract_7z() { unar -output-directory "$2" -force-overwrite -no-directory "$1"; }
	else
		check_deps_error_not_found 'p7zip'
	fi
}

# display a message if a required dependency is missing
# USAGE: check_deps_error_not_found $command_name
# CALLED BY: check_deps check_deps_7z
check_deps_error_not_found() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='%s est introuvable. Installez-le avant de lancer ce script.\n'
		;;
		('en'|*)
			string='%s not found. Install it before running this script.\n'
		;;
	esac
	printf "$string" "$1"
	return 1
}

# display script usage
# USAGE: help
# NEEDED VARS: (LANG)
# CALLS: help_checksum help_compression help_prefix help_package
help() {
	local string
	local string_archive
	case "${LANG%_*}" in
		('fr')
			string='Utilisation :'
			string_archive='Ce script reconnaît l’archive suivante :'
			string_archives='Ce script reconnaît les archives suivantes :'
		;;
		('en'|*)
			string='Usage:'
			string_archive='This script can work on the following archive:'
			string_archives='This script can work on the following archives:'
		;;
	esac
	printf '\n'
	printf '%s %s [OPTION]… [ARCHIVE]\n\n' "$string" "${0##*/}"
	
	printf 'OPTIONS\n\n'
	help_architecture
	printf '\n'
	help_checksum
	printf '\n'
	help_compression
	printf '\n'
	help_prefix
	printf '\n'
	help_package
	printf '\n'
	help_dryrun
	printf '\n'

	printf 'ARCHIVE\n\n'
	archives_get_list
	if [ -n "${ARCHIVES_LIST##* *}" ]; then
		printf '%s\n' "$string_archive"
	else
		printf '%s\n' "$string_archives"
	fi
	for archive in $ARCHIVES_LIST; do
		printf '%s\n' "$(eval printf -- '%b' \"\$$archive\")"
	done
	printf '\n'
}

# display --architecture option usage
# USAGE: help_architecture
# NEEDED VARS: (LANG)
# CALLED BY: help
help_architecture() {
	local string
	local string_all
	local string_32
	local string_64
	local string_auto
	case "${LANG%_*}" in
		('fr')
			string='Choix de l’architecture à construire'
			string_all='toutes les architectures disponibles (méthode par défaut)'
			string_32='paquets 32-bit seulement'
			string_64='paquets 64-bit seulement'
			string_auto='paquets pour l’architecture du système courant uniquement'
		;;
		('en'|*)
			string='Target architecture choice'
			string_all='all available architectures (default method)'
			string_32='32-bit packages only'
			string_64='64-bit packages only'
			string_auto='packages for current system architecture only'
		;;
	esac
	printf -- '--architecture=all|32|64|auto\n'
	printf -- '--architecture all|32|64|auto\n\n'
	printf '\t%s\n\n' "$string"
	printf '\tall\t%s\n' "$string_all"
	printf '\t32\t%s\n' "$string_32"
	printf '\t64\t%s\n' "$string_64"
	printf '\tauto\t%s\n' "$string_auto"
}

# display --checksum option usage
# USAGE: help_checksum
# NEEDED VARS: (LANG)
# CALLED BY: help
help_checksum() {
	local string
	local string_md5
	local string_none
	case "${LANG%_*}" in
		('fr')
			string='Choix de la méthode de vérification d’intégrité de l’archive'
			string_md5='vérification via md5sum (méthode par défaut)'
			string_none='pas de vérification'
		;;
		('en'|*)
			string='Archive integrity verification method choice'
			string_md5='md5sum verification (default method)'
			string_none='no verification'
		;;
	esac
	printf -- '--checksum=md5|none\n'
	printf -- '--checksum md5|none\n\n'
	printf '\t%s\n\n' "$string"
	printf '\tmd5\t%s\n' "$string_md5"
	printf '\tnone\t%s\n' "$string_none"
}

# display --compression option usage
# USAGE: help_compression
# NEEDED VARS: (LANG)
# CALLED BY: help
help_compression() {
	local string
	local string_none
	local string_gzip
	local string_xz
	case "${LANG%_*}" in
		('fr')
			string='Choix de la méthode de compression des paquets générés'
			string_none='pas de compression (méthode par défaut)'
			string_gzip='compression gzip (rapide)'
			string_xz='compression xz (plus lent mais plus efficace que gzip)'
		;;
		('en'|*)
			string='Generated packages compression method choice'
			string_none='no compression (default method)'
			string_gzip='gzip compression (fast)'
			string_xz='xz compression (slower but more efficient than gzip)'
		;;
	esac
	printf -- '--compression=none|gzip|xz\n'
	printf -- '--compression none|gzip|xz\n\n'
	printf '\t%s\n\n' "$string"
	printf '\tnone\t%s\n' "$string_none"
	printf '\tgzip\t%s\n' "$string_gzip"
	printf '\txz\t%s\n' "$string_xz"
}

# display --prefix option usage
# USAGE: help_prefix
# NEEDED VARS: (LANG)
# CALLED BY: help
help_prefix() {
	local string
	local string_absolute
	local string_default
	case "${LANG%_*}" in
		('fr')
			string='Choix du chemin d’installation du jeu'
			string_absolute='Cette option accepte uniquement un chemin absolu.'
			string_default='chemin par défaut :'
		;;
		('en'|*)
			string='Game installation path choice'
			string_absolute='This option accepts an absolute path only.'
			string_default='default path:'
		;;
	esac
	printf -- '--prefix=$path\n'
	printf -- '--prefix $path\n\n'
	printf '\t%s\n\n' "$string"
	printf '\t%s\n' "$string_absolute"
	printf '\t%s /usr/local\n' "$string_default"
}

# display --package option usage
# USAGE: help_package
# NEEDED VARS: (LANG)
# CALLED BY: help
help_package() {
	local string
	local string_default
	local string_arch
	local string_deb
	case "${LANG%_*}" in
		('fr')
			string='Choix du type de paquet à construire'
			string_default='(type par défaut)'
			string_arch='paquet .pkg.tar (Arch Linux)'
			string_deb='paquet .deb (Debian, Ubuntu)'
		;;
		('en'|*)
			string='Generated package Type choice'
			string_default='(default type)'
			string_arch='.pkg.tar package (Arch Linux)'
			string_deb='.deb package (Debian, Ubuntu)'
		;;
	esac
	printf -- '--package=arch|deb\n'
	printf -- '--package arch|deb\n\n'
	printf '\t%s\n\n' "$string"
	printf '\tarch\t%s' "$string_arch"
	[ "$DEFAULT_OPTION_PACKAGE" = 'arch' ] && printf ' %s\n' "$string_default" || printf '\n'
	printf '\tdeb\t%s' "$string_deb"
	[ "$DEFAULT_OPTION_PACKAGE" = 'deb' ] && printf ' %s\n' "$string_default" || printf '\n'
}

# display --dry-run option usage
# USAGE: help_dryrun
# NEEDED VARS: (LANG)
# CALLED BY: help
help_dryrun() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Effectue des tests de syntaxe mais n’extrait pas de données et ne construit pas de paquets.'
		;;
		('en'|*)
			string='Run syntax checks but do not extract data nor build packages.'
		;;
	esac
	printf -- '--dry-run\n\n'
	printf '\t%s\n\n' "$string"
}

# select package architecture to build
# USAGE: select_package_architecture
# NEEDED_VARS: OPTION_ARCHITECTURE PACKAGES_LIST
# CALLS: select_package_architecture_warning_unavailable select_package_architecture_error_unknown select_package_architecture_warning_unsupported
select_package_architecture() {
	[ "$OPTION_ARCHITECTURE" = 'all' ] && return 0
	local version_major_target
	local version_minor_target
	version_major_target="${target_version%%.*}"
	version_minor_target=$(printf '%s' "$target_version" | cut --delimiter='.' --fields=2)
	if [ $version_major_target -lt 2 ] || [ $version_minor_target -lt 6 ]; then
		select_package_architecture_warning_unsupported
		OPTION_ARCHITECTURE='all'
		export OPTION_ARCHITECTURE
		return 0
	fi
	if [ "$OPTION_ARCHITECTURE" = 'auto' ]; then
		case "$(uname --machine)" in
			('i686')
				OPTION_ARCHITECTURE='32'
			;;
			('x86_64')
				OPTION_ARCHITECTURE='64'
			;;
			(*)
				select_package_architecture_warning_unknown
				OPTION_ARCHITECTURE='all'
				export OPTION_ARCHITECTURE
				return 0
			;;
		esac
		export OPTION_ARCHITECTURE
		select_package_architecture
		return 0
	fi
	local package_arch
	local packages_list_32
	local packages_list_64
	local packages_list_all
	for package in $PACKAGES_LIST; do
		package_arch="$(eval printf -- '%b' \"\$${package}_ARCH\")"
		case "$package_arch" in
			('32')
				packages_list_32="$packages_list_32 $package"
			;;
			('64')
				packages_list_64="$packages_list_64 $package"
			;;
			(*)
				packages_list_all="$packages_list_all $package"
			;;
		esac
	done
	case "$OPTION_ARCHITECTURE" in
		('32')
			if [ -z "$packages_list_32" ]; then
				select_package_architecture_warning_unavailable
				OPTION_ARCHITECTURE='all'
				return 0
			fi
			PACKAGES_LIST="$packages_list_32 $packages_list_all"
		;;
		('64')
			if [ -z "$packages_list_64" ]; then
				select_package_architecture_warning_unavailable
				OPTION_ARCHITECTURE-'all'
				return 0
			fi
			PACKAGES_LIST="$packages_list_64 $packages_list_all"
		;;
		(*)
			select_package_architecture_error_unknown
		;;
	esac
	export PACKAGES_LIST
}

# display an error if selected architecture is not available
# USAGE: select_package_architecture_warning_unavailable
# NEEDED_VARS: (LANG) OPTION_ARCHITECTURE
# CALLED_BY: select_package_architecture
select_package_architecture_warning_unavailable() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='L’architecture demandée n’est pas disponible : %s\n'
		;;
		('en'|*)
			string='Selected architecture is not available: %s\n'
		;;
	esac
	print_warning
	printf "$string" "$OPTION_ARCHITECTURE"
}

# display an error if selected architecture is not supported
# USAGE: select_package_architecture_error_unknown
# NEEDED_VARS: (LANG) OPTION_ARCHITECTURE
# CALLED_BY: select_package_architecture
select_package_architecture_error_unknown() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='L’architecture demandée n’est pas supportée : %s\n'
		;;
		('en'|*)
			string='Selected architecture is not supported: %s\n'
		;;
	esac
	print_error
	printf "$string" "$OPTION_ARCHITECTURE"
	exit 1
}

# display a warning if using --architecture on a pre-2.6 script
# USAGE: select_package_architecture_warning_unsupported
# NEEDED_VARS: (LANG)
# CALLED_BY: select_package_architecture
select_package_architecture_warning_unsupported() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='L’option --architecture n’est pas gérée par ce script.'
		;;
		('en'|*)
			string='--architecture option is not supported by this script.'
		;;
	esac
	print_warning
	printf '%s\n\n' "$string"
}

# get version of current package, exported as PKG_VERSION
# USAGE: get_package_version
# NEEDED_VARS: PKG
get_package_version() {
	use_package_specific_value "${ARCHIVE}_VERSION"
	PKG_VERSION="$(eval printf -- '%b' \"\$${ARCHIVE}_VERSION\")"
	if [ -z "$PKG_VERSION" ]; then
		PKG_VERSION='1.0-1'
	fi
	PKG_VERSION="${PKG_VERSION}+$script_version"
	export PKG_VERSION
}

# set temporary directories
# USAGE: set_temp_directories $pkg[…]
# NEEDED VARS: (ARCHIVE_SIZE) GAME_ID (LANG) (PWD) (XDG_CACHE_HOME) (XDG_RUNTIME_DIR)
# CALLS: set_temp_directories_error_no_size set_temp_directories_error_not_enough_space set_temp_directories_pkg testvar
set_temp_directories() {

	# If $PLAYIT_WORKDIR is already set, delete it before setting a new one
	[ "$PLAYIT_WORKDIR" ] && rm --force --recursive "$PLAYIT_WORKDIR"

	# If there is only a single package, make it the default one for the current instance
	[ $# = 1 ] && PKG="$1"

	# Generate an unique name for the current instance
	local name
	name="play.it/$(mktemp --dry-run "${GAME_ID}.XXXXX")"

	# Look for a directory with enough free space to work in
	if [ "$ARCHIVE_SIZE" ]; then
		local needed_space
		needed_space=$((ARCHIVE_SIZE * 2))
	else
		set_temp_directories_error_no_size
	fi
	[ "$XDG_RUNTIME_DIR" ] || XDG_RUNTIME_DIR="/run/user/$(id -u)"
	[ "$XDG_CACHE_HOME" ]  || XDG_CACHE_HOME="$HOME/.cache"
	local free_space_run
	free_space_run=$(df --output=avail "$XDG_RUNTIME_DIR" 2>/dev/null | tail --lines=1)
	local free_space_tmp
	free_space_tmp=$(df --output=avail /tmp 2>/dev/null | tail --lines=1)
	local free_space_cache
	free_space_cache=$(df --output=avail "$XDG_CACHE_HOME" 2>/dev/null | tail --lines=1)
	local free_space_pwd
	free_space_pwd=$(df --output=avail "$PWD" 2>/dev/null | tail --lines=1)
	if [ -w "$XDG_RUNTIME_DIR" ] && [ $free_space_run -ge $needed_space ]; then
		PLAYIT_WORKDIR="$XDG_RUNTIME_DIR/$name"
	elif [ -w '/tmp' ] && [ $free_space_tmp -ge $needed_space ]; then
		PLAYIT_WORKDIR="/tmp/$name"
		if [ ! -e "${PLAYIT_WORKDIR%/*}" ]; then
			mkdir --parents "${PLAYIT_WORKDIR%/*}"
			chmod 777 "${PLAYIT_WORKDIR%/*}"
		fi
	elif [ -w "$XDG_CACHE_HOME" ] && [ $free_space_cache -ge $needed_space ]; then
		PLAYIT_WORKDIR="$XDG_CACHE_HOME/$name"
	elif [ -w "$PWD" ] && [ $free_space_pwd -ge $needed_space ]; then
		PLAYIT_WORKDIR="$PWD/$name"
	else
		set_temp_directories_error_not_enough_space
	fi
	export PLAYIT_WORKDIR

	# If $PLAYIT_WORKDIR is an already existing directory, set a new one
	if [ -e "$PLAYIT_WORKDIR" ]; then
		set_temp_directories
		return 0
	fi

	# Set $postinst and $prerm
	mkdir --parents "$PLAYIT_WORKDIR/scripts"
	postinst="$PLAYIT_WORKDIR/scripts/postinst"
	export postinst
	prerm="$PLAYIT_WORKDIR/scripts/prerm"
	export prerm

	# Set temporary directories for each package to build
	for pkg in "$@"; do
		testvar "$pkg" 'PKG'
		set_temp_directories_pkg $pkg
	done
}

# set package-secific temporary directory
# USAGE: set_temp_directories_pkg $pkg
# NEEDED VARS: (ARCHIVE) (OPTION_PACKAGE) PLAYIT_WORKDIR (PKG_ARCH) PKG_ID|GAME_ID
# CALLED BY: set_temp_directories
set_temp_directories_pkg() {
	PKG="$1"

	# Get package ID
	use_archive_specific_value "${PKG}_ID"
	local pkg_id
	pkg_id="$(eval printf -- '%b' \"\$${PKG}_ID\")"
	if [ -z "$pkg_id" ]; then
		eval ${PKG}_ID=\"$GAME_ID\"
		export ${PKG}_ID
		pkg_id="$GAME_ID"
	fi

	# Get package architecture
	local pkg_architecture
	set_architecture "$PKG"

	# Set $PKG_PATH
	if [ "$OPTION_PACKAGE" = 'arch' ] && [ "$(eval printf -- '%b' \"\$${PKG}_ARCH\")" = '32' ]; then
		pkg_id="lib32-$pkg_id"
	fi
	get_package_version
	eval ${PKG}_PATH=\"$PLAYIT_WORKDIR/${pkg_id}_${PKG_VERSION}_${pkg_architecture}\"
	export ${PKG}_PATH
}

# display an error if set_temp_directories() is called before setting $ARCHIVE_SIZE
# USAGE: set_temp_directories_error_no_size
# NEEDED VARS: (LANG)
# CALLS: print_error
# CALLED BY: set_temp_directories
set_temp_directories_error_no_size() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='$ARCHIVE_SIZE doit être défini avant tout appel à set_temp_directories().\n'
		;;
		('en'|*)
			string='$ARCHIVE_SIZE must be set before any call to set_temp_directories().\n'
		;;
	esac
	printf "$string"
	return 1
}

# display an error if there is not enough free space to work in any of the tested directories
# USAGE: set_temp_directories_error_not_enough_space
# NEEDED VARS: (LANG)
# CALLS: print_error
# CALLED BY: set_temp_directories
set_temp_directories_error_not_enough_space() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='Il n’y a pas assez d’espace libre dans les différents répertoires testés :\n'
		;;
		('en'|*)
			string='There is not enough free space in the tested directories:\n'
		;;
	esac
	printf "$string"
	for path in "$XDG_RUNTIME_DIR" '/tmp' "$XDG_CACHE_HOME" "$PWD"; do
		printf '%s\n' "$path"
	done
	return 1
}

# extract data from given archive
# USAGE: extract_data_from $archive[…]
# NEEDED_VARS: (ARCHIVE) (ARCHIVE_PASSWD) (ARCHIVE_TYPE) (LANG) (PLAYIT_WORKDIR)
# CALLS: liberror extract_7z extract_data_from_print
extract_data_from() {
	[ "$PLAYIT_WORKDIR" ] || return 1
	[ "$ARCHIVE" ] || return 1
	local file
	for file in "$@"; do
		extract_data_from_print "$(basename "$file")"

		local destination
		destination="$PLAYIT_WORKDIR/gamedata"
		mkdir --parents "$destination"
		if [ "$DRY_RUN" = '1' ]; then
			printf '\n'
			return 0
		fi
		local archive_type
		archive_type="$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")"
		case "$archive_type" in
			('7z')
				extract_7z "$file" "$destination"
			;;
			('cabinet')
				cabextract -d "$destination" -q "$file"
				tolower "$destination"
			;;
			('debian')
				dpkg-deb --extract "$file" "$destination"
			;;
			('innosetup'*)
				archive_extraction_innosetup "$archive_type" "$file" "$destination"
			;;
			('msi')
				msiextract --directory "$destination" "$file" 1>/dev/null 2>&1
				tolower "$destination"
			;;
			('mojosetup')
				bsdtar --directory "$destination" --extract --file "$file"
				set_standard_permissions "$destination"
			;;
			('nix_stage1')
				local input_blocksize
				input_blocksize=$(head --lines=514 "$file" | wc --bytes | tr --delete ' ')
				dd if="$file" ibs=$input_blocksize skip=1 obs=1024 conv=sync 2>/dev/null | gunzip --stdout | tar --extract --file - --directory "$destination"
			;;
			('nix_stage2')
				tar --extract --xz --file "$file" --directory "$destination"
			;;
			('rar'|'nullsoft-installer')
				# compute archive password from GOG id
				if [ -z "$ARCHIVE_PASSWD" ] && [ -n "$(eval printf -- '%b' \"\$${ARCHIVE}_GOGID\")" ]; then
					ARCHIVE_PASSWD="$(printf '%s' "$(eval printf -- '%b' \"\$${ARCHIVE}_GOGID\")" | md5sum | cut -d' ' -f1)"
				fi
				if [ -n "$ARCHIVE_PASSWD" ]; then
					UNAR_OPTIONS="-password $ARCHIVE_PASSWD"
				fi
				unar -no-directory -output-directory "$destination" $UNAR_OPTIONS "$file" 1>/dev/null
			;;
			('tar'|'tar.gz')
				tar --extract --file "$file" --directory "$destination"
			;;
			('zip')
				unzip -d "$destination" "$file" 1>/dev/null
			;;
			('zip_unclean'|'mojosetup_unzip')
				set +o errexit
				unzip -d "$destination" "$file" 1>/dev/null 2>&1
				set -o errexit
				set_standard_permissions "$destination"
			;;
			(*)
				liberror 'ARCHIVE_TYPE' 'extract_data_from'
			;;
		esac

		if [ "$archive_type" != 'innosetup' ]; then
			print_ok
		fi
	done
}

# print data extraction message
# USAGE: extract_data_from_print $file
# NEEDED VARS: (LANG)
# CALLED BY: extract_data_from
extract_data_from_print() {
	case "${LANG%_*}" in
		('fr')
			string='Extraction des données de %s'
		;;
		('en'|*)
			string='Extracting data from %s'
		;;
	esac
	printf "$string" "$1"
}

# extract data from InnoSetup archive
# USAGE: archive_extraction_innosetup $archive_type $archive $destination
# CALLS: archive_extraction_innosetup_error_version
archive_extraction_innosetup() {
	local archive
	local archive_type
	local destination
	local options
	archive_type="$1"
	archive="$2"
	destination="$3"
	options='--progress=1 --silent'
	if [ "$archive_type" != 'innosetup_nolowercase' ]; then
		options="$options --lowercase"
	fi
	if ( innoextract --list --silent "$archive" 2>&1 1>/dev/null |\
		head --lines=1 |\
		grep --ignore-case 'unexpected setup data version' 1>/dev/null )
	then
		archive_extraction_innosetup_error_version "$archive"
	fi
	printf '\n'
	innoextract $options --extract --output-dir "$destination" "$file"
}

# print error if available version of innoextract is too low
# USAGE: archive_extraction_innosetup_error_version $archive
# CALLED BY: archive_extraction_innosetup
archive_extraction_innosetup_error_version() {
	local archive
	archive="$1"
	print_error
	case "${LANG%_*}" in
		('fr')
			string='La version de innoextract disponible sur ce système est trop ancienne pour extraire les données de l’archive suivante :'
		;;
		('en'|*)
			string='Available innoextract version is too old to extract data from the following archive:'
		;;
	esac
	printf "$string %s\\n" "$archive"
	exit 1
}

# prepare package layout by putting files from archive in the right packages
# directories
# USAGE: prepare_package_layout [$pkg…]
# NEEDED VARS: (LANG) (PACKAGES_LIST) PLAYIT_WORKDIR (PKG_PATH)
prepare_package_layout() {
	if [ -z "$1" ]; then
		[ -n "$PACKAGES_LIST" ] || prepare_package_layout_error_no_list
		prepare_package_layout $PACKAGES_LIST
		return 0
	fi
	for package in "$@"; do
		PKG="$package"
		organize_data "GAME_${PKG#PKG_}" "$PATH_GAME"
		organize_data "DOC_${PKG#PKG_}"  "$PATH_DOC"
		for i in $(seq 0 9); do
			organize_data "GAME${i}_${PKG#PKG_}" "$PATH_GAME"
			organize_data "DOC${i}_${PKG#PKG_}"  "$PATH_DOC"
		done
	done
}

# display an error when calling prepare_package_layout() without argument while
# $PACKAGES_LIST is unset or empty
# USAGE: prepare_package_layout_error_no_list
# NEEDED VARS: (LANG)
prepare_package_layout_error_no_list() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='prepare_package_layout ne peut pas être appelé sans argument si $PACKAGES_LIST n’est pas défini.'
		;;
		('en'|*)
			string='prepare_package_layout can not be called without argument if $PACKAGES_LIST is not set.'
		;;
	esac
	printf '%s\n' "$string"
	return 1
}

# put files from archive in the right package directories
# USAGE: organize_data $id $path
# NEEDED VARS: (LANG) PLAYIT_WORKDIR (PKG) (PKG_PATH)
organize_data() {
	[ -n "$PKG" ] || organize_data_error_missing_pkg
	if [ "$OPTION_ARCHITECTURE" != all ] && [ -n "${PACKAGES_LIST##*$PKG*}" ]; then
		skipping_pkg_warning 'organize_data' "$PKG"
		return 0
	fi
	local pkg_path
	if [ "$DRY_RUN" = '1' ]; then
		pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
		[ -n "$pkg_path" ] || missing_pkg_error 'organize_data' "$PKG"
		return 0
	fi
	use_archive_specific_value "ARCHIVE_${1}_PATH"
	use_archive_specific_value "ARCHIVE_${1}_FILES"
	local archive_path
	archive_path="$(eval printf -- '%b' \"\$ARCHIVE_${1}_PATH\")"
	local archive_files
	archive_files="$(eval printf -- '%b' \"\$ARCHIVE_${1}_FILES\")"

	if [ "$archive_path" ] && [ "$archive_files" ] && [ -d "$PLAYIT_WORKDIR/gamedata/$archive_path" ]; then
		pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
		[ -n "$pkg_path" ] || missing_pkg_error 'organize_data' "$PKG"
		pkg_path="${pkg_path}$2"
		mkdir --parents "$pkg_path"
		(
			cd "$PLAYIT_WORKDIR/gamedata/$archive_path"
			for file in $archive_files; do
				if [ -e "$file" ]; then
					cp --recursive --force --link --parents --no-dereference --preserve=links "$file" "$pkg_path"
					rm --recursive "$file"
				fi
			done
		)
	fi
}

# display an error when calling organize_data() with $PKG unset or empty
# USAGE: organize_data_error_missing_pkg
# NEEDED VARS: (LANG)
organize_data_error_missing_pkg() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='organize_data ne peut pas être appelé si $PKG n’est pas défini.\n'
		;;
		('en'|*)
			string='organize_data can not be called if $PKG is not set.\n'
		;;
	esac
	printf "$string"
	return 1
}

# update dependencies list with commands needed for icons extraction
# USAGE: icons_list_dependencies
icons_list_dependencies() {
	local script
	script="$0"
	if grep\
		--regexp="^APP_[^_]\\+_ICON='.\\+'"\
		--regexp="^APP_[^_]\\+_ICON_.\\+='.\\+'"\
		"$script" 1>/dev/null
	then
		SCRIPT_DEPS="$SCRIPT_DEPS identify"
		if grep\
			--regexp="^APP_[^_]\\+_ICON='.\\+\\.bmp'"\
			--regexp="^APP_[^_]\\+_ICON_.\\+='.\\+\\.bmp'"\
			--regexp="^APP_[^_]\\+_ICON='.\\+\\.ico'"\
			--regexp="^APP_[^_]\\+_ICON_.\\+='.\\+\\.ico'"\
			"$script" 1>/dev/null
		then
			SCRIPT_DEPS="$SCRIPT_DEPS convert"
		fi
		if grep\
			--regexp="^APP_[^_]\\+_ICON='.\\+\\.exe'"\
			--regexp="^APP_[^_]\\+_ICON_.\\+='.\\+\\.exe'"\
			"$script" 1>/dev/null
		then
			SCRIPT_DEPS="$SCRIPT_DEPS convert wrestool"
		fi
	fi
	export SCRIPT_DEPS
}

# get .png file(s) from various icon sources in current package
# USAGE: icons_get_from_package $app[…]
# NEEDED VARS: APP_ID|GAME_ID PATH_GAME PATH_ICON_BASE PLAYIT_WORKDIR PKG
# CALLS: icons_get_from_path
icons_get_from_package() {
	local path
	local path_pkg
	path_pkg="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	[ -n "$path_pkg" ] || missing_pkg_error 'icons_get_from_package' "$PKG"
	path="${path_pkg}${PATH_GAME}"
	icons_get_from_path "$path" "$@"
}
# compatibility alias
extract_and_sort_icons_from() { icons_get_from_package "$@"; }

# get .png file(s) from various icon sources in temporary work directory
# USAGE: icons_get_from_package $app[…]
# NEEDED VARS: APP_ID|GAME_ID PATH_ICON_BASE PLAYIT_WORKDIR PKG
# CALLS: icons_get_from_path
icons_get_from_workdir() {
	local path
	path="$PLAYIT_WORKDIR/gamedata"
	icons_get_from_path "$path" "$@"
}
# compatibility alias
get_icon_from_temp_dir() { icons_get_from_workdir "$@"; }

# get .png file(s) from various icon sources
# USAGE: icons_get_from_path $directory $app[…]
# NEEDED VARS: APP_ID|GAME_ID PATH_ICON_BASE PLAYIT_WORKDIR PKG
# CALLS: icon_extract_png_from_file icons_include_png_from_directory testvar liberror
icons_get_from_path() {
	local app
	local destination
	local directory
	local file
	local icon
	local list
	local path_pkg
	local wrestool_id
	directory="$1"
	shift 1
	destination="$PLAYIT_WORKDIR/icons"
	path_pkg="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	[ -n "$path_pkg" ] || missing_pkg_error 'icons_get_from_package' "$PKG"
	for app in "$@"; do
		testvar "$app" 'APP' || liberror 'app' 'icons_get_from_package'
		list="$(eval printf -- '%b' \"\$${app}_ICONS_LIST\")"
		[ -n "$list" ] || list="${app}_ICON"
		for icon in $list; do
			use_archive_specific_value "$icon"
			file="$(eval printf -- '%b' \"\$$icon\")"
			wrestool_id="$(eval printf -- '%b' \"\$${icon}_ID\")"
			icon_extract_png_from_file "$directory/$file" "$destination"
		done
		icons_include_png_from_directory "$app" "$destination"
	done
}

# extract .png file(s) from target file
# USAGE: icon_extract_png_from_file $file $destination
# CALLS: icon_convert_bmp_to_png icon_extract_png_from_exe icon_extract_png_from_ico icon_copy_png
# CALLED BY: icons_get_from_path
icon_extract_png_from_file() {
	local destination
	local extension
	local file
	file="$1"
	destination="$2"
	extension="${file##*.}"
	mkdir --parents "$destination"
	case "$extension" in
		('bmp')
			icon_convert_bmp_to_png "$file" "$destination"
		;;
		('exe')
			icon_extract_png_from_exe "$file" "$destination"
		;;
		('ico')
			icon_extract_png_from_ico "$file" "$destination"
		;;
		('png')
			icon_copy_png "$file" "$destination"
		;;
		(*)
			liberror 'extension' 'icon_extract_png_from_file'
		;;
	esac
}
# compatibility alias
extract_icon_from() {
	local destination
	local file
	destination="$PLAYIT_WORKDIR/icons"
	for file in "$@"; do
		extension="${file##*.}"
		if [ "$extension" = 'exe' ]; then
			mkdir --parents "$destination"
			icon_extract_ico_from_exe "$file" "$destination"
		else
			icon_extract_png_from_file "$file" "$destination"
		fi
	done
}


# extract .png file(s) for .exe
# USAGE: icon_extract_png_from_exe $file $destination
# CALLS: icon_extract_ico_from_exe icon_extract_png_from_ico
# CALLED BY: icon_extract_png_from_file
icon_extract_png_from_exe() {
	[ "$DRY_RUN" = '1' ] && return 0
	local destination
	local file
	file="$1"
	destination="$2"
	icon_extract_ico_from_exe "$file" "$destination"
	for file in "$destination"/*.ico; do
		icon_extract_png_from_ico "$file" "$destination"
		rm "$file"
	done
}

# extract .ico file(s) from .exe
# USAGE: icon_extract_ico_from_exe $file $destination
# CALLED BY: icon_extract_png_from_exe
icon_extract_ico_from_exe() {
	[ "$DRY_RUN" = '1' ] && return 0
	local destination
	local file
	local options
	file="$1"
	destination="$2"
	[ "$wrestool_id" ] && options="--name=$wrestool_id"
	wrestool --extract --type=14 $options --output="$destination" "$file" 2>/dev/null
}

# convert .bmp file to .png
# USAGE: icon_convert_bmp_to_png $file $destination
# CALLED BY: icon_extract_png_from_file
icon_convert_bmp_to_png() { icon_convert_to_png "$@"; }

# extract .png file(s) from .ico
# USAGE: icon_extract_png_from_ico $file $destination
# CALLED BY: icon_extract_png_from_file icon_extract_png_from_exe
icon_extract_png_from_ico() { icon_convert_to_png "$@"; }

# convert multiple icon formats to .png
# USAGE: icon_convert_to_png $file $destination
# CALLED BY: icon_extract_png_from_bmp icon_extract_png_from_ico
icon_convert_to_png() {
	[ "$DRY_RUN" = '1' ] && return 0
	local destination
	local file
	local name
	file="$1"
	destination="$2"
	name="${file##*/}"
	convert "$file" "$destination/${name%.*}.png"
}

# copy .png file to directory
# USAGE: icon_copy_png $file $destination
# CALLED BY: icon_extract_png_from_file
icon_copy_png() {
	[ "$DRY_RUN" = '1' ] && return 0
	local destination
	local file
	file="$1"
	destination="$2"
	cp "$file" "$destination"
}

# get .png file(s) from target directory and put them in current package
# USAGE: icons_include_png_from_directory $app $directory
# NEEDED VARS: APP_ID|GAME_ID PATH_ICON_BASE PKG
# CALLS: icon_get_resolution_from_file
# CALLED BY: icons_get_from_path
icons_include_png_from_directory() {
	[ "$DRY_RUN" = '1' ] && return 0
	local app
	local directory
	local file
	local path
	local path_icon
	local path_pkg
	local resolution
	app="$1"
	directory="$2"
	name="$(eval printf -- '%b' \"\$${app}_ID\")"
	[ -n "$name" ] || name="$GAME_ID"
	path_pkg="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	[ -n "$path_pkg" ] || missing_pkg_error 'icons_include_png_from_directory' "$PKG"
	for file in "$directory"/*.png; do
		icon_get_resolution_from_file "$file"
		path_icon="$PATH_ICON_BASE/$resolution/apps"
		path="${path_pkg}${path_icon}"
		mkdir --parents "$path"
		mv "$file" "$path/$name.png"
	done
}
# comaptibility alias
sort_icons() {
	local app
	local directory
	directory="$PLAYIT_WORKDIR/icons"
	for app in "$@"; do
		icons_include_png_from_directory "$app" "$directory"
	done
}

# get image resolution for target file, exported as $resolution
# USAGE: icon_get_resolution_from_file $file
# CALLED BY: icons_include_png_from_directory
icon_get_resolution_from_file() {
	local file
	local version_major_target
	local version_minor_target
	file="$1"
	version_major_target="${target_version%%.*}"
	version_minor_target=$(printf '%s' "$target_version" | cut --delimiter='.' --fields=2)
	if
		{ [ $version_major_target -lt 2 ] || [ $version_minor_target -lt 8 ] ; } &&
		[ -n "${file##* *}" ]
	then
		field=2
		while [ -z "$resolution" ] || [ -n "$(printf '%s' "$resolution" | sed 's/[0-9]*x[0-9]*//')" ]; do
			resolution="$(identify $file | sed "s;^$file ;;" | cut --delimiter=' ' --fields=$field)"
			field=$((field + 1))
		done
	else
		resolution="$(identify "$file" | sed "s;^$file ;;" | cut --delimiter=' ' --fields=2)"
	fi
	export resolution
}

# link icons in place post-installation from game directory
# USAGE: icons_linking_postinst $app[…]
# NEEDED VARS: APP_ID|GAME_ID PATH_GAME PATH_ICON_BASE PKG
icons_linking_postinst() {
	[ "$DRY_RUN" = '1' ] && return 0
	local app
	local file
	local icon
	local list
	local name
	local path
	local path_icon
	local path_pkg
	local version_major_target
	local version_minor_target
	version_major_target="${target_version%%.*}"
	version_minor_target=$(printf '%s' "$target_version" | cut --delimiter='.' --fields=2)
	path_pkg="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	[ -n "$path_pkg" ] || missing_pkg_error 'icons_linking_postinst' "$PKG"
	path="${path_pkg}${PATH_GAME}"
	for app in "$@"; do
		list="$(eval printf -- '%b' \"\$${app}_ICONS_LIST\")"
		[ "$list" ] || list="${app}_ICON"
		name="$(eval printf -- '%b' \"\$${app}_ID\")"
		[ "$name" ] || name="$GAME_ID"
		for icon in $list; do
			file="$(eval printf -- '%b' \"\$$icon\")"
			if
				{ [ $version_major_target -lt 2 ] || [ $version_minor_target -lt 8 ] ; } &&
				( ls "$path/$file" >/dev/null 2>&1 || ls "$path"/$file >/dev/null 2>&1 )
			then
				icon_get_resolution_from_file "$path/$file"
			else
				icon_get_resolution_from_file "${PKG_DATA_PATH}${PATH_GAME}/$file"
			fi
			path_icon="$PATH_ICON_BASE/$resolution/apps"
			if
				{ [ $version_major_target -lt 2 ] || [ $version_minor_target -lt 8 ] ; } &&
				[ -n "${file##* *}" ]
			then
				cat >> "$postinst" <<- EOF
				if [ ! -e "$path_icon/$name.png" ]; then
				  mkdir --parents "$path_icon"
				  ln --symbolic "$PATH_GAME"/$file "$path_icon/$name.png"
				fi
				EOF
			else
				cat >> "$postinst" <<- EOF
				if [ ! -e "$path_icon/$name.png" ]; then
				  mkdir --parents "$path_icon"
				  ln --symbolic "$PATH_GAME/$file" "$path_icon/$name.png"
				fi
				EOF
			fi
			cat >> "$prerm" <<- EOF
			if [ -e "$path_icon/$name.png" ]; then
			  rm "$path_icon/$name.png"
			  rmdir --parents --ignore-fail-on-non-empty "$path_icon"
			fi
			EOF
		done
	done
}
# compatibility alias
postinst_icons_linking() { icons_linking_postinst "$@"; }

# move icons to the target package
# USAGE: icons_move_to $pkg
# NEEDED VARS: PATH_ICON_BASE PKG
icons_move_to() {
	local destination
	local source
	destination="$1"
	destination_path="$(eval printf -- '%b' \"\$${destination}_PATH\")"
	[ -n "$destination_path" ] || missing_pkg_error 'icons_move_to' "$destination"
	source="$PKG"
	source_path="$(eval printf -- '%b' \"\$${source}_PATH\")"
	[ -n "$source_path" ] || missing_pkg_error 'icons_move_to' "$source"
	[ "$DRY_RUN" = '1' ] && return 0
	(
		cd "$source_path"
		cp --link --parents --recursive --no-dereference --preserve=links "./$PATH_ICON_BASE" "$destination_path"
		rm --recursive "./$PATH_ICON_BASE"
		rmdir --ignore-fail-on-non-empty --parents "./${PATH_ICON_BASE%/*}"
	)
}
# compatibility alias
move_icons_to() { icons_move_to "$@"; }

# print installation instructions
# USAGE: print_instructions $pkg[…]
# NEEDED VARS: (GAME_NAME) (OPTION_PACKAGE) (PACKAGES_LIST)
print_instructions() {
	[ "$GAME_NAME" ] || return 1
	if [ $# = 0 ]; then
		print_instructions $PACKAGES_LIST
		return 0
	fi
	local package_arch
	local packages_list_32
	local packages_list_64
	local packages_list_all
	local string
	for package in "$@"; do
		package_arch="$(eval printf -- '%b' \"\$${package}_ARCH\")"
		case "$package_arch" in
			('32')
				packages_list_32="$packages_list_32 $package"
			;;
			('64')
				packages_list_64="$packages_list_64 $package"
			;;
			(*)
				packages_list_all="$packages_list_all $package"
			;;
		esac

	done
	case "${LANG%_*}" in
		('fr')
			string='\nInstallez %s en lançant la série de commandes suivantes en root :\n'
		;;
		('en'|*)
			string='\nInstall %s by running the following commands as root:\n'
		;;
	esac
	printf "$string" "$GAME_NAME"
	if [ -n "$packages_list_32" ] && [ -n "$packages_list_64" ]; then
		print_instructions_architecture_specific '32' $packages_list_all $packages_list_32
		print_instructions_architecture_specific '64' $packages_list_all $packages_list_64
	else
		case $OPTION_PACKAGE in
			('arch')
				print_instructions_arch "$@"
			;;
			('deb')
				print_instructions_deb "$@"
			;;
			(*)
				liberror 'OPTION_PACKAGE' 'print_instructions'
			;;
		esac
	fi
	printf '\n'
}

# print installation instructions for Arch Linux - 32-bit version
# USAGE: print_instructions_architecture_specific $pkg[…]
# CALLS: print_instructions_arch print_instructions_deb
print_instructions_architecture_specific() {
	case "${LANG%_*}" in
		('fr')
			string='\nversion %s-bit :\n'
		;;
		('en'|*)
			string='\n%s-bit version:\n'
		;;
	esac
	printf "$string" "$1"
	shift 1
	case $OPTION_PACKAGE in
		('arch')
			print_instructions_arch "$@"
		;;
		('deb')
			print_instructions_deb "$@"
		;;
		(*)
			liberror 'OPTION_PACKAGE' 'print_instructions'
		;;
	esac
}

# print installation instructions for Arch Linux
# USAGE: print_instructions_arch $pkg[…]
print_instructions_arch() {
	local pkg_path
	local str_format
	printf 'pacman -U'
	for pkg in "$@"; do
		if [ "$OPTION_ARCHITECTURE" != all ] && [ -n "${PACKAGES_LIST##*$pkg*}" ]; then
			skipping_pkg_warning 'print_instructions_arch' "$pkg"
			return 0
		fi
		pkg_path="$(eval printf -- '%b' \"\$${pkg}_PKG\")"
		if [ -z "${pkg_path##* *}" ]; then
			str_format=' "%s"'
		else
			str_format=' %s'
		fi
		printf "$str_format" "$pkg_path"
	done
	printf '\n'
}

# print installation instructions for Debian
# USAGE: print_instructions_deb $pkg[…]
# CALLS: print_instructions_deb_apt print_instructions_deb_dpkg
print_instructions_deb() {
	if command -v apt >/dev/null 2>&1; then
		debian_version="$(apt --version | cut --delimiter=' ' --fields=2)"
		debian_version_major="$(printf '%s' "$debian_version" | cut --delimiter='.' --fields='1')"
		debian_version_minor="$(printf '%s' "$debian_version" | cut --delimiter='.' --fields='2')"
		if [ $debian_version_major -ge 2 ] ||\
		   [ $debian_version_major = 1 ] &&\
		   [ ${debian_version_minor%~*} -ge 1 ]; then
			print_instructions_deb_apt "$@"
		else
			print_instructions_deb_dpkg "$@"
		fi
	else
		print_instructions_deb_dpkg "$@"
	fi
}

# print installation instructions for Debian with apt
# USAGE: print_instructions_deb_apt $pkg[…]
# CALLS: print_instructions_deb_common
# CALLED BY: print_instructions_deb
print_instructions_deb_apt() {
	printf 'apt install'
	print_instructions_deb_common "$@"
}

# print installation instructions for Debian with dpkg + apt-get
# USAGE: print_instructions_deb_dpkg $pkg[…]
# CALLS: print_instructions_deb_common
# CALLED BY: print_instructions_deb
print_instructions_deb_dpkg() {
	printf 'dpkg -i'
	print_instructions_deb_common "$@"
	printf 'apt-get install -f\n'
}

# print installation instructions for Debian (common part)
# USAGE: print_instructions_deb_common $pkg[…]
# CALLED BY: print_instructions_deb_apt print_instructions_deb_dpkg
print_instructions_deb_common() {
	local pkg_path
	local str_format
	for pkg in "$@"; do
		if [ "$OPTION_ARCHITECTURE" != all ] && [ -n "${PACKAGES_LIST##*$pkg*}" ]; then
			skipping_pkg_warning 'print_instructions_deb_common' "$pkg"
			return 0
		fi
		pkg_path="$(eval printf -- '%b' \"\$${pkg}_PKG\")"
		if [ -z "${pkg_path##* *}" ]; then
			str_format=' "%s"'
		else
			str_format=' %s'
		fi
		printf "$str_format" "$pkg_path"
	done
	printf '\n'
}

# alias calling write_bin() and write_desktop()
# USAGE: write_launcher $app[…]
# NEEDED VARS: (APP_CAT) APP_ID|GAME_ID APP_EXE APP_LIBS APP_NAME|GAME_NAME APP_OPTIONS APP_POSTRUN APP_PRERUN APP_TYPE CONFIG_DIRS CONFIG_FILES DATA_DIRS DATA_FILES GAME_ID (LANG) PATH_BIN PATH_DESK PATH_GAME PKG (PKG_PATH)
# CALLS: write_bin write_dekstop
write_launcher() {
	if [ "$OPTION_ARCHITECTURE" != all ] && [ -n "${PACKAGES_LIST##*$PKG*}" ]; then
		skipping_pkg_warning 'write_launcher' "$PKG"
		return 0
	fi
	write_bin "$@"
	write_desktop "$@"
}

# write launcher script
# USAGE: write_bin $app[…]
# NEEDED VARS: APP_ID|GAME_ID APP_EXE APP_LIBS APP_OPTIONS APP_POSTRUN APP_PRERUN APP_TYPE CONFIG_DIRS CONFIG_FILES DATA_DIRS DATA_FILES GAME_ID (LANG) PATH_BIN PATH_GAME PKG (PKG_PATH)
# CALLS: liberror testvar write_bin_build_wine write_bin_run_dosbox write_bin_run_native write_bin_run_native_noprefix write_bin_run_scummvm write_bin_run_wine write_bin_set_native_noprefix write_bin_set_scummvm write_bin_set_wine write_bin_winecfg
# CALLED BY: write_launcher
write_bin() {
	local pkg_path
	if [ "$OPTION_ARCHITECTURE" != all ] && [ -n "${PACKAGES_LIST##*$PKG*}" ]; then
		skipping_pkg_warning 'write_bin' "$PKG"
		return 0
	fi
	pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	[ -n "$pkg_path" ] || missing_pkg_error 'write_bin' "$PKG"
	local app
	local app_id
	local app_exe
	local app_libs
	local app_options
	local app_postrun
	local app_prerun
	local app_type
	local file
	for app in "$@"; do
		testvar "$app" 'APP' || liberror 'app' 'write_bin'
		[ "$DRY_RUN" = '1' ] && continue

		# Get app-specific variables
		if [ -n "$(eval printf -- '%b' \"\$${app}_ID\")" ]; then
			app_id="$(eval printf -- '%b' \"\$${app}_ID\")"
		else
			app_id="$GAME_ID"
		fi

		app_type="$(eval printf -- '%b' \"\$${app}_TYPE\")"
		if [ "$app_type" != 'scummvm' ]; then
			use_package_specific_value "${app}_EXE"
			use_package_specific_value "${app}_LIBS"
			use_package_specific_value "${app}_OPTIONS"
			use_package_specific_value "${app}_POSTRUN"
			use_package_specific_value "${app}_PRERUN"
			app_exe="$(eval printf -- '%b' \"\$${app}_EXE\")"
			app_libs="$(eval printf -- '%b' \"\$${app}_LIBS\")"
			app_options="$(eval printf -- '%b' \"\$${app}_OPTIONS\")"
			app_postrun="$(eval printf -- '%b' \"\$${app}_POSTRUN\")"
			app_prerun="$(eval printf -- '%b' \"\$${app}_PRERUN\")"
			if [ "$app_type" = 'native' ] ||\
			   [ "$app_type" = 'native_no-prefix' ]; then
				chmod +x "${pkg_path}${PATH_GAME}/$app_exe"
			fi
		fi

		# Write winecfg launcher for WINE games
		if [ "$app_type" = 'wine' ] || \
		   [ "$app_type" = 'wine32' ] || \
		   [ "$app_type" = 'wine64' ] || \
		   [ "$app_type" = 'wine-staging' ] || \
		   [ "$app_type" = 'wine32-staging' ] || \
		   [ "$app_type" = 'wine64-staging' ]
		then
			write_bin_winecfg
		fi

		file="${pkg_path}${PATH_BIN}/$app_id"
		mkdir --parents "${file%/*}"

		# Write launcher headers
		cat > "$file" <<- EOF
		#!/bin/sh
		# script generated by ./play.it $library_version - http://wiki.dotslashplay.it/
		set -o errexit

		EOF

		# Write launcher
		if [ "$app_type" = 'scummvm' ]; then
			write_bin_set_scummvm
		elif [ "$app_type" = 'native_no-prefix' ]; then
			write_bin_set_native_noprefix
		else
			# Set executable, options and libraries
			if [ "$app_id" != "${GAME_ID}_winecfg" ]; then
				cat >> "$file" <<- EOF
				# Set executable file

				APP_EXE='$app_exe'
				APP_OPTIONS="$app_options"
				LD_LIBRARY_PATH="$app_libs:\$LD_LIBRARY_PATH"
				export LD_LIBRARY_PATH

				EOF
			fi

			# Set game path and user-writable files
			cat >> "$file" <<- EOF
			# Set game-specific variables

			GAME_ID='$GAME_ID'
			PATH_GAME='$PATH_GAME'

			CONFIG_DIRS='$CONFIG_DIRS'
			CONFIG_FILES='$CONFIG_FILES'

			DATA_DIRS='$DATA_DIRS'
			DATA_FILES='$DATA_FILES'

			EOF

			# Set user-specific directories names and paths
			cat >> "$file" <<- 'EOF'
			# Set prefix name

			[ "$PREFIX_ID" ] || PREFIX_ID="$GAME_ID"

			# Set prefix-specific variables

			[ "$XDG_CONFIG_HOME" ] || XDG_CONFIG_HOME="$HOME/.config"
			[ "$XDG_DATA_HOME" ] || XDG_DATA_HOME="$HOME/.local/share"

			PATH_CONFIG="$XDG_CONFIG_HOME/$PREFIX_ID"
			PATH_DATA="$XDG_DATA_HOME/games/$PREFIX_ID"
			EOF
			if [ "$app_type" = 'wine' ] || \
			   [ "$app_type" = 'wine32' ] || \
			   [ "$app_type" = 'wine64' ] || \
			   [ "$app_type" = 'wine-staging' ] || \
			   [ "$app_type" = 'wine32-staging' ] || \
			   [ "$app_type" = 'wine64-staging' ]
			then
				write_bin_set_wine
			else
				cat >> "$file" <<- 'EOF'
				PATH_PREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"

				EOF
			fi

			# Set generic functions
			cat >> "$file" <<- 'EOF'
			# Set ./play.it functions

			init_prefix_dirs() {
			  (
			    cd "$1"
			    for dir in $2; do
			      if [ ! -e "$dir" ]; then
			        if [ -e "$PATH_PREFIX/$dir" ]; then
			          (
			            cd "$PATH_PREFIX"
			            cp --dereference --parents --recursive "$dir" "$1"
			          )
			        elif [ -e "$PATH_GAME/$dir" ]; then
			          (
			            cd "$PATH_GAME"
			            cp --parents --recursive "$dir" "$1"
			          )
			        else
			          mkdir --parents "$dir"
			        fi
			      fi
			      rm --force --recursive "$PATH_PREFIX/$dir"
			      mkdir --parents "$PATH_PREFIX/${dir%/*}"
			      ln --symbolic "$(readlink --canonicalize-existing "$dir")" "$PATH_PREFIX/$dir"
			    done
			  )
			}

			init_prefix_files() {
			  (
			    local file_prefix
			    local file_real
			    cd "$1"
			    find . -type f | while read -r file; do
			      if [ -e "$PATH_PREFIX/$file" ]; then
			        file_prefix="$(readlink -e "$PATH_PREFIX/$file")"
			      else
			        unset file_prefix
			      fi
			      file_real="$(readlink -e "$file")"
			      if [ "$file_real" != "$file_prefix" ]; then
			        if [ "$file_prefix" ]; then
			          rm --force "$PATH_PREFIX/$file"
			        fi
			        mkdir --parents "$PATH_PREFIX/${file%/*}"
			        ln --symbolic "$file_real" "$PATH_PREFIX/$file"
			      fi
			    done
			  )
			  (
			    cd "$PATH_PREFIX"
			    for file in $2; do
			      if [ -e "$file" ] && [ ! -e "$1/$file" ]; then
			        cp --parents "$file" "$1"
			        rm --force "$file"
			        ln --symbolic "$1/$file" "$file"
			      fi
			    done
			  )
			}

			init_userdir_files() {
			  (
			    cd "$PATH_GAME"
			    for file in $2; do
			      if [ ! -e "$1/$file" ] && [ -e "$file" ]; then
			        cp --parents "$file" "$1"
			      fi
			    done
			  )
			}
			EOF

			# Build game prefix
			cat >> "$file" <<- 'EOF'
			# Build prefix
			EOF
			if [ "$app_type" = 'wine' ] || \
			   [ "$app_type" = 'wine32' ] || \
			   [ "$app_type" = 'wine64' ] || \
			   [ "$app_type" = 'wine-staging' ] || \
			   [ "$app_type" = 'wine32-staging' ] || \
			   [ "$app_type" = 'wine64-staging' ]
			then
				write_bin_build_wine
			fi
			cat >> "$file" <<- 'EOF'
			if [ ! -e "$PATH_PREFIX" ]; then
			  mkdir --parents "$PATH_PREFIX"
			fi
			cp --force --recursive --symbolic-link --update "$PATH_GAME"/* "$PATH_PREFIX"
			if [ ! -e "$PATH_CONFIG" ]; then
			  mkdir --parents "$PATH_CONFIG"
			fi
			init_userdir_files "$PATH_CONFIG" "$CONFIG_FILES"
			if [ ! -e "$PATH_DATA" ]; then
			  mkdir --parents "$PATH_DATA"
			fi
			init_userdir_files "$PATH_DATA" "$DATA_FILES"
			init_prefix_files "$PATH_CONFIG" "$CONFIG_FILES"
			init_prefix_files "$PATH_DATA" "$DATA_FILES"
			init_prefix_dirs "$PATH_CONFIG" "$CONFIG_DIRS"
			init_prefix_dirs "$PATH_DATA" "$DATA_DIRS"

			EOF
		fi

		case $app_type in
			('dosbox')
				write_bin_run_dosbox
			;;
			('native')
				write_bin_run_native
			;;
			('native_no-prefix')
				write_bin_run_native_noprefix
			;;
			('scummvm')
				write_bin_run_scummvm
			;;
			('wine'|'wine32'|'wine64'|'wine-staging'|'wine32-staging'|'wine64-staging')
				write_bin_run_wine
			;;
		esac

		cat >> "$file" <<- 'EOF'

		exit 0
		EOF

		sed -i 's/  /\t/g' "$file"
		chmod 755 "$file"
	done
}

# write menu entry
# USAGE: write_desktop $app[…]
# NEEDED VARS: (APP_CAT) APP_ID|GAME_ID APP_NAME|GAME_NAME APP_TYPE (LANG) PATH_DESK PKG (PKG_PATH)
# CALLS: liberror testvar write_desktop_winecfg
# CALLED BY: write_launcher
write_desktop() {
	if [ "$OPTION_ARCHITECTURE" != all ] && [ -n "${PACKAGES_LIST##*$PKG*}" ]; then
		skipping_pkg_warning 'write_desktop' "$PKG"
		return 0
	fi
	local app
	local app_cat
	local app_id
	local app_name
	local app_type
	local pkg_path
	local target
	for app in "$@"; do
		testvar "$app" 'APP' || liberror 'app' 'write_desktop'
		[ "$DRY_RUN" = '1' ] && continue

		app_type="$(eval printf -- '%b' \"\$${app}_TYPE\")"
		if [ "$winecfg_desktop" != 'done' ] && \
		   { [ "$app_type" = 'wine' ] || \
		     [ "$app_type" = 'wine32' ] || \
		     [ "$app_type" = 'wine64' ] || \
		     [ "$app_type" = 'wine-staging' ] || \
		     [ "$app_type" = 'wine32-staging' ] || \
		     [ "$app_type" = 'wine64-staging' ] ; }
		then
			winecfg_desktop='done'
			write_desktop_winecfg
		fi

		if [ -n "$(eval printf -- '%b' \"\$${app}_ID\")" ]; then
			app_id="$(eval printf -- '%b' \"\$${app}_ID\")"
		else
			app_id="$GAME_ID"
		fi

		if [ -n "$(eval printf -- '%b' \"\$${app}_NAME\")" ]; then
			app_name="$(eval printf -- '%b' \"\$${app}_NAME\")"
		else
			app_name="$GAME_NAME"
		fi

		if [ -n "$(eval printf -- '%b' \"\$${app}_CAT\")" ]; then
			app_cat="$(eval printf -- '%b' \"\$${app}_CAT\")"
		else
			app_cat='Game'
		fi

		pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
		[ -n "$pkg_path" ] || missing_pkg_error 'write_desktop' "$PKG"
		target="${pkg_path}${PATH_DESK}/${app_id}.desktop"
		mkdir --parents "${target%/*}"
		cat > "$target" <<- EOF
		[Desktop Entry]
		Version=1.0
		Type=Application
		Name=$app_name
		Icon=$app_id
		Exec=$PATH_BIN/$app_id
		Categories=$app_cat
		EOF
	done
}

# write launcher script - run the DOSBox game
# USAGE: write_bin_run_dosbox
# CALLED BY: write_bin_run
write_bin_run_dosbox() {
	cat >> "$file" <<- 'EOF'
	# Run the game

	cd "$PATH_PREFIX"
	dosbox -c "mount c .
	c:
	EOF

	if [ "$GAME_IMAGE" ]; then
		case "$GAME_IMAGE_TYPE" in
			('cdrom')
				cat >> "$file" <<- EOF
				mount d $GAME_IMAGE -t cdrom
				EOF
			;;
			('iso'|*)
				cat >> "$file" <<- EOF
				imgmount d $GAME_IMAGE -t iso -fs iso
				EOF
			;;
		esac
	fi

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	$APP_EXE $APP_OPTIONS $@
	EOF

	if [ "$app_postrun" ]; then
		cat >> "$file" <<- EOF
		$app_postrun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	exit"
	EOF
}

# write launcher script - set native game common vars (no prefix)
# USAGE: write_bin_set_native_noprefix
# CALLED BY: write_bin
write_bin_set_native_noprefix() {
	cat >> "$file" <<- EOF
	# Set executable file

	APP_EXE='$app_exe'
	APP_OPTIONS="$app_options"
	LD_LIBRARY_PATH="$app_libs:\$LD_LIBRARY_PATH"
	export LD_LIBRARY_PATH

	# Set game-specific variables

	GAME_ID='$GAME_ID'
	PATH_GAME='$PATH_GAME'

	EOF
}

# write launcher script - run the native game
# USAGE: write_bin_run_native
# CALLED BY: write_bin
write_bin_run_native() {
	cat >> "$file" <<- 'EOF'
	# Copy the game binary into the user prefix

	if [ -e "$PATH_DATA/$APP_EXE" ]; then
	  source_dir="$PATH_DATA"
	else
	  source_dir="$PATH_GAME"
	fi

	(
	  cd "$source_dir"
	  cp --parents --dereference --remove-destination "$APP_EXE" "$PATH_PREFIX"
	)

	# Run the game

	cd "$PATH_PREFIX"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	"./$APP_EXE" $APP_OPTIONS $@
	EOF
}

# write launcher script - run the native game (no prefix)
# USAGE: write_bin_run_native_noprefix
# CALLED BY: write_bin
write_bin_run_native_noprefix() {
	cat >> "$file" <<- 'EOF'
	# Run the game

	cd "$PATH_GAME"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	"./$APP_EXE" $APP_OPTIONS $@
	EOF
}

# write launcher script - set ScummVM-specific common vars
# USAGE: write_bin_set_scummvm
write_bin_set_scummvm() {
	cat >> "$file" <<- EOF
	# Set game-specific variables

	GAME_ID='$GAME_ID'
	PATH_GAME='$PATH_GAME'
	SCUMMVM_ID='$(eval printf -- '%b' \"\$${app}_SCUMMID\")'

	EOF
}

# write launcher script - run the ScummVM game
# USAGE: write_bin_run_scummvm
# CALLED BY: write_bin_run
write_bin_run_scummvm() {
	cat >> "$file" <<- 'EOF'
	# Run the game

	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	scummvm -p "$PATH_GAME" $APP_OPTIONS $@ $SCUMMVM_ID
	EOF
}

# write winecfg launcher script
# USAGE: write_bin_winecfg
# NEEDED VARS: APP_POSTRUN APP_PRERUN CONFIG_DIRS CONFIG_FILES DATA_DIRS DATA_FILES GAME_ID (LANG) PATH_BIN PATH_GAME PKG (PKG_PATH)
# CALLS: write_bin
# CALLED BY: write_bin
write_bin_winecfg() {
	if [ "$winecfg_launcher" != '1' ]; then
		winecfg_launcher='1'
		APP_WINECFG_ID="${GAME_ID}_winecfg"
		APP_WINECFG_TYPE='wine'
		APP_WINECFG_EXE='winecfg'
		write_bin 'APP_WINECFG'
		local target
		target="${pkg_path}${PATH_BIN}/$APP_WINECFG_ID"
		sed --in-place 's/# Run the game/# Run WINE configuration/' "$target"
		sed --in-place 's/^cd "$PATH_PREFIX"//'                     "$target"
		sed --in-place 's/wine "$APP_EXE" $APP_OPTIONS $@/winecfg/' "$target"
	fi
}

# write launcher script - set WINE-specific prefix-specific vars
# USAGE: write_bin_set_wine
# CALLED BY: write_bin
write_bin_set_wine() {
	local winearch
	case "$app_type" in
		('wine'|'wine-staging')
			use_archive_specific_value "${PKG}_ARCH"
			local architecture
			architecture="$(eval printf -- '%b' \"\$${PKG}_ARCH\")"
			case "$architecture" in
				('32') winearch='win32' ;;
				('64') winearch='win64' ;;
			esac
		;;
		('wine32'|'wine32-staging') winearch='win32' ;;
		('wine64'|'wine64-staging') winearch='win64' ;;
	esac
	cat >> "$file" <<- EOF
	WINEARCH='$winearch'
	export WINEARCH
	EOF
	cat >> "$file" <<- 'EOF'
	WINEDEBUG='-all'
	export WINEDEBUG
	WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'
	export WINEDLLOVERRIDES
	WINEPREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"
	export WINEPREFIX
	# Work around WINE bug 41639
	FREETYPE_PROPERTIES="truetype:interpreter-version=35"
	export FREETYPE_PROPERTIES

	PATH_PREFIX="$WINEPREFIX/drive_c/$GAME_ID"

	EOF
}

# write launcher script - set WINE-specific user-writable directories
# USAGE: write_bin_build_wine
# NEEDED VARS: APP_WINETRICKS
# CALLED BY: write_bin
write_bin_build_wine() {
	cat >> "$file" <<- 'EOF'
	if ! [ -e "$WINEPREFIX" ]; then
	  mkdir --parents "${WINEPREFIX%/*}"
	  # Use LANG=C to avoid localized directory names
	  LANG=C wineboot --init 2>/dev/null
	EOF

	if ! { [ $version_major_target -lt 2 ] || [ $version_minor_target -lt 8 ] ; }; then
		cat >> "$file" <<- 'EOF'
		  # Remove most links pointing outside of the WINE prefix
		  rm "$WINEPREFIX/dosdevices/z:"
		  find "$WINEPREFIX/drive_c/users/$(whoami)" -type l | while read directory; do
		    rm "$directory"
		    mkdir "$directory"
		  done
		EOF
	fi

	if [ "$APP_WINETRICKS" ]; then
		cat >> "$file" <<- EOF
		  winetricks $APP_WINETRICKS
		EOF
	fi

	if [ "$APP_REGEDIT" ]; then
		cat >> "$file" <<- EOF
		  for reg_file in $APP_REGEDIT; do
		EOF
		cat >> "$file" <<- 'EOF'
		  (
		    cd "$WINEPREFIX/drive_c/"
		    cp "$PATH_GAME/$reg_file" .
		    reg_file_basename="${reg_file##*/}"
		    wine regedit "$reg_file_basename"
		    rm "$reg_file_basename"
		  )
		  done
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	fi
	EOF
}

# write launcher script - run the WINE game
# USAGE: write_bin_run_wine
# CALLED BY: write_bin
write_bin_run_wine() {
	cat >> "$file" <<- 'EOF'
	# Run the game

	cd "$PATH_PREFIX"
	EOF

	cat >> "$file" <<- EOF
	$app_prerun
	wine "\$APP_EXE" \$APP_OPTIONS \$@
	$app_postrun
	EOF
}

# write winecfg menu entry
# USAGE: write_desktop_winecfg
# NEEDED VARS: (LANG) PATH_DESK PKG (PKG_PATH)
# CALLS: write_desktop
# CALLED BY: write_desktop
write_desktop_winecfg() {
	local pkg_path
	pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	[ -n "$pkg_path" ] || missing_pkg_error 'write_desktop_winecfg' "$PKG"
	APP_WINECFG_ID="${GAME_ID}_winecfg"
	APP_WINECFG_NAME="$GAME_NAME - WINE configuration"
	APP_WINECFG_CAT='Settings'
	write_desktop 'APP_WINECFG'
	sed --in-place 's/Icon=.\+/Icon=winecfg/' "${pkg_path}${PATH_DESK}/${APP_WINECFG_ID}.desktop"
}

# write package meta-data
# USAGE: write_metadata [$pkg…]
# NEEDED VARS: (ARCHIVE) GAME_NAME (OPTION_PACKAGE) PACKAGES_LIST (PKG_ARCH) PKG_DEPS_ARCH PKG_DEPS_DEB PKG_DESCRIPTION PKG_ID (PKG_PATH) PKG_PROVIDE
# CALLS: liberror pkg_write_arch pkg_write_deb set_architecture testvar
write_metadata() {
	if [ $# = 0 ]; then
		write_metadata $PACKAGES_LIST
		return 0
	fi
	local pkg_architecture
	local pkg_description
	local pkg_id
	local pkg_maint
	local pkg_path
	local pkg_provide
	for pkg in "$@"; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'write_metadata'
		if [ "$OPTION_ARCHITECTURE" != all ] && [ -n "${PACKAGES_LIST##*$pkg*}" ]; then
			skipping_pkg_warning 'write_metadata' "$pkg"
			continue
		fi

		# Set package-specific variables
		set_architecture "$pkg"
		pkg_id="$(eval printf -- '%b' \"\$${pkg}_ID\")"
		pkg_maint="$(whoami)@$(hostname)"
		pkg_path="$(eval printf -- '%b' \"\$${pkg}_PATH\")"
		[ -n "$pkg_path" ] || missing_pkg_error 'write_metadata' "$pkg"
		[ "$DRY_RUN" = '1' ] && continue
		pkg_provide="$(eval printf -- '%b' \"\$${pkg}_PROVIDE\")"

		use_archive_specific_value "${pkg}_DESCRIPTION"
		pkg_description="$(eval printf -- '%b' \"\$${pkg}_DESCRIPTION\")"

		case $OPTION_PACKAGE in
			('arch')
				pkg_write_arch
			;;
			('deb')
				pkg_write_deb
			;;
			(*)
				liberror 'OPTION_PACKAGE' 'write_metadata'
			;;
		esac
	done
	rm  --force "$postinst" "$prerm"
}

# build .pkg.tar or .deb package
# USAGE: build_pkg [$pkg…]
# NEEDED VARS: (OPTION_COMPRESSION) (LANG) (OPTION_PACKAGE) PACKAGES_LIST (PKG_PATH) PLAYIT_WORKDIR
# CALLS: liberror pkg_build_arch pkg_build_deb testvar
build_pkg() {
	if [ $# = 0 ]; then
		build_pkg $PACKAGES_LIST
		return 0
	fi
	local pkg_path
	for pkg in "$@"; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
		if [ "$OPTION_ARCHITECTURE" != all ] && [ -n "${PACKAGES_LIST##*$pkg*}" ]; then
			skipping_pkg_warning 'build_pkg' "$pkg"
			return 0
		fi
		pkg_path="$(eval printf -- '%b' \"\$${pkg}_PATH\")"
		[ -n "$pkg_path" ] || missing_pkg_error 'build_pkg' "$PKG"
		case $OPTION_PACKAGE in
			('arch')
				pkg_build_arch "$pkg_path"
			;;
			('deb')
				pkg_build_deb "$pkg_path"
			;;
			(*)
				liberror 'OPTION_PACKAGE' 'build_pkg'
			;;
		esac
	done
}

# print package building message
# USAGE: pkg_print $file
# NEEDED VARS: (LANG)
# CALLED BY: pkg_build_arch pkg_build_deb
pkg_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Construction de %s'
		;;
		('en'|*)
			string='Building %s'
		;;
	esac
	printf "$string" "$1"
}

# print package building message
# USAGE: pkg_build_print_already_exists $file
# NEEDED VARS: (LANG)
# CALLED BY: pkg_build_arch pkg_build_deb
pkg_build_print_already_exists() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='%s existe déjà.\n'
		;;
		('en'|*)
			string='%s already exists.\n'
		;;
	esac
	printf "$string" "$1"
}

# guess package format to build from host OS
# USAGE: packages_guess_format $variable_name
# NEEDED VARS: (LANG) DEFAULT_OPTION_PACKAGE
packages_guess_format() {
	local guessed_host_os
	local variable_name
	eval variable_name=\"$1\"
	if [ -e '/etc/os-release' ]; then
		guessed_host_os="$(grep '^ID=' '/etc/os-release' | cut --delimiter='=' --fields=2)"
	elif command -v lsb_release >/dev/null 2>&1; then
		guessed_host_os="$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')"
	fi
	case "$guessed_host_os" in
		('debian'|\
		 'ubuntu'|\
		 'linuxmint'|\
		 'handylinux')
			eval $variable_name=\'deb\'
		;;
		('arch'|\
		 'manjaro'|'manjarolinux')
			eval $variable_name=\'arch\'
		;;
		(*)
			print_warning
			case "${LANG%_*}" in
				('fr')
					string1='L’auto-détection du format de paquet le plus adapté a échoué.\n'
					string2='Le format de paquet %s sera utilisé par défaut.\n'
				;;
				('en'|*)
					string1='Most pertinent package format auto-detection failed.\n'
					string2='%s package format will be used by default.\n'
				;;
			esac
			printf "$string1"
			printf "$string2" "$DEFAULT_OPTION_PACKAGE"
			printf '\n'
		;;
	esac
	export $variable_name
}

# write .pkg.tar package meta-data
# USAGE: pkg_write_arch
# NEEDED VARS: GAME_NAME PKG_DEPS_ARCH
# CALLED BY: write_metadata
pkg_write_arch() {
	local pkg_deps
	if [ "$(eval printf -- '%b' \"\$${pkg}_DEPS\")" ]; then
		pkg_set_deps_arch $(eval printf -- '%b' \"\$${pkg}_DEPS\")
	fi
	use_archive_specific_value "${pkg}_DEPS_ARCH"
	if [ "$(eval printf -- '%b' \"\$${pkg}_DEPS_ARCH\")" ]; then
		pkg_deps="$pkg_deps $(eval printf -- '%b' \"\$${pkg}_DEPS_ARCH\")"
	fi
	local pkg_size
	pkg_size=$(du --total --block-size=1 --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
	local target
	target="$pkg_path/.PKGINFO"

	PKG="$pkg"
	get_package_version

	mkdir --parents "${target%/*}"

	cat > "$target" <<- EOF
	pkgname = $pkg_id
	pkgver = $PKG_VERSION
	packager = $pkg_maint
	builddate = $(date +"%m%d%Y")
	size = $pkg_size
	arch = $pkg_architecture
	EOF

	if [ -n "$pkg_description" ]; then
		cat >> "$target" <<- EOF
		pkgdesc = $GAME_NAME - $pkg_description - ./play.it script version $script_version
		EOF
	else
		cat >> "$target" <<- EOF
		pkgdesc = $GAME_NAME - ./play.it script version $script_version
		EOF
	fi

	for dep in $pkg_deps; do
		cat >> "$target" <<- EOF
		depend = $dep
		EOF
	done

	if [ -n "$pkg_provide" ]; then
		cat >> "$target" <<- EOF
		conflict = $pkg_provide
		provides = $pkg_provide
		EOF
	fi

	target="$pkg_path/.INSTALL"

	if [ -e "$postinst" ]; then
		cat >> "$target" <<- EOF
		post_install() {
		$(cat "$postinst")
		}

		post_upgrade() {
		post_install
		}
		EOF
	fi

	if [ -e "$prerm" ]; then
		cat >> "$target" <<- EOF
		pre_remove() {
		$(cat "$prerm")
		}

		pre_upgrade() {
		pre_remove
		}
		EOF
	fi
}

# set list or Arch Linux dependencies from generic names
# USAGE: pkg_set_deps_arch $dep[…]
# CALLS: pkg_set_deps_arch32 pkg_set_deps_arch64
# CALLED BY: pkg_write_arch
pkg_set_deps_arch() {
	use_archive_specific_value "${pkg}_ARCH"
	local architecture
	architecture="$(eval printf -- '%b' \"\$${pkg}_ARCH\")"
	case $architecture in
		('32')
			pkg_set_deps_arch32 "$@"
		;;
		('64')
			pkg_set_deps_arch64 "$@"
		;;
	esac
}

# set list or Arch Linux 32-bit dependencies from generic names
# USAGE: pkg_set_deps_arch32 $dep[…]
# CALLED BY: pkg_set_deps_arch
pkg_set_deps_arch32() {
	for dep in "$@"; do
		case $dep in
			('alsa')
				pkg_dep='lib32-alsa-lib lib32-alsa-plugins'
			;;
			('bzip2')
				pkg_dep='lib32-bzip2'
			;;
			('dosbox')
				pkg_dep='dosbox'
			;;
			('freetype')
				pkg_dep='lib32-freetype2'
			;;
			('gcc32')
				pkg_dep='gcc-multilib'
			;;
			('gconf')
				pkg_dep='lib32-gconf'
			;;
			('glibc')
				pkg_dep='lib32-glibc'
			;;
			('glu')
				pkg_dep='lib32-glu'
			;;
			('glx')
				pkg_dep='lib32-libgl'
			;;
			('gtk2')
				pkg_dep='lib32-gtk2'
			;;
			('json')
				pkg_dep='lib32-json-c'
			;;
			('libcurl')
				pkg_dep='lib32-curl'
			;;
			('libcurl-gnutls')
				pkg_dep='lib32-libcurl-gnutls'
			;;
			('libstdc++')
				pkg_dep='lib32-gcc-libs'
			;;
			('libxrandr')
				pkg_dep='lib32-libxrandr'
			;;
			('nss')
				pkg_dep='lib32-nss'
			;;
			('openal')
				pkg_dep='lib32-openal'
			;;
			('pulseaudio')
				pkg_dep='pulseaudio'
			;;
			('sdl1.2')
				pkg_dep='lib32-sdl'
			;;
			('sdl2')
				pkg_dep='lib32-sdl2'
			;;
			('sdl2_image')
				pkg_dep='lib32-sdl2_image'
			;;
			('sdl2_mixer')
				pkg_dep='lib32-sdl2_mixer'
			;;
			('vorbis')
				pkg_dep='lib32-libvorbis'
			;;
			('wine'|'wine32'|'wine64')
				pkg_dep='wine'
			;;
			('wine-staging'|'wine32-staging'|'wine64-staging')
				pkg_dep='wine-staging'
			;;
			('winetricks')
				pkg_dep='winetricks'
			;;
			('xcursor')
				pkg_dep='lib32-libxcursor'
			;;
			('xft')
				pkg_dep='lib32-libxft'
			;;
			('xgamma')
				pkg_dep='xorg-xgamma'
			;;
			('xrandr')
				pkg_dep='xorg-xrandr'
			;;
			(*)
				pkg_deps="$dep"
			;;
		esac
		pkg_deps="$pkg_deps $pkg_dep"
	done
}

# set list or Arch Linux 64-bit dependencies from generic names
# USAGE: pkg_set_deps_arch64 $dep[…]
# CALLED BY: pkg_set_deps_arch
pkg_set_deps_arch64() {
	for dep in "$@"; do
		case $dep in
			('alsa')
				pkg_dep='alsa-lib alsa-plugins'
			;;
			('bzip2')
				pkg_dep='bzip2'
			;;
			('dosbox')
				pkg_dep='dosbox'
			;;
			('freetype')
				pkg_dep='freetype2'
			;;
			('gcc32')
				pkg_dep='gcc-multilib'
			;;
			('gconf')
				pkg_dep='gconf'
			;;
			('glibc')
				pkg_dep='glibc'
			;;
			('glu')
				pkg_dep='glu'
			;;
			('glx')
				pkg_dep='libgl'
			;;
			('gtk2')
				pkg_dep='gtk2'
			;;
			('json')
				pkg_dep='json-c'
			;;
			('libcurl')
				pkg_dep='curl'
			;;
			('libcurl-gnutls')
				pkg_dep='libcurl-gnutls'
			;;
			('libstdc++')
				pkg_dep='gcc-libs'
			;;
			('libxrandr')
				pkg_dep='libxrandr'
			;;
			('nss')
				pkg_dep='nss'
			;;
			('openal')
				pkg_dep='openal'
			;;
			('pulseaudio')
				pkg_dep='pulseaudio'
			;;
			('sdl1.2')
				pkg_dep='sdl'
			;;
			('sdl2')
				pkg_dep='sdl2'
			;;
			('sdl2_image')
				pkg_dep='sdl2_image'
			;;
			('sdl2_mixer')
				pkg_dep='sdl2_mixer'
			;;
			('vorbis')
				pkg_dep='libvorbis'
			;;
			('wine'|'wine32'|'wine64')
				pkg_dep='wine'
			;;
			('winetricks')
				pkg_dep='winetricks'
			;;
			('xcursor')
				pkg_dep='libxcursor'
			;;
			('xft')
				pkg_dep='libxft'
			;;
			('xgamma')
				pkg_dep='xorg-xgamma'
			;;
			('xrandr')
				pkg_dep='xorg-xrandr'
			;;
			(*)
				pkg_dep="$dep"
			;;
		esac
		pkg_deps="$pkg_deps $pkg_dep"
	done
}

# build .pkg.tar package
# USAGE: pkg_build_arch $pkg_path
# NEEDED VARS: (OPTION_COMPRESSION) (LANG) PLAYIT_WORKDIR
# CALLS: pkg_print
# CALLED BY: build_pkg
pkg_build_arch() {
	local pkg_filename
	pkg_filename="$PWD/${1##*/}.pkg.tar"

	if [ -e "$pkg_filename" ]; then
		pkg_build_print_already_exists "${pkg_filename##*/}"
		eval ${pkg}_PKG=\"$pkg_filename\"
		export ${pkg}_PKG
		return 0
	fi

	local tar_options
	tar_options='--create --group=root --owner=root'

	case $OPTION_COMPRESSION in
		('gzip')
			tar_options="$tar_options --gzip"
			pkg_filename="${pkg_filename}.gz"
		;;
		('xz')
			tar_options="$tar_options --xz"
			pkg_filename="${pkg_filename}.xz"
		;;
		('none') ;;
		(*)
			liberror 'OPTION_COMPRESSION' 'pkg_build_arch'
		;;
	esac

	pkg_print "${pkg_filename##*/}"
	if [ "$DRY_RUN" = '1' ]; then
		printf '\n'
		eval ${pkg}_PKG=\"$pkg_filename\"
		export ${pkg}_PKG
		return 0
	fi

	(
		cd "$1"
		local files
		files='.PKGINFO *'
		if [ -e '.INSTALL' ]; then
			files=".INSTALL $files"
		fi
		tar $tar_options --file "$pkg_filename" $files
	)

	eval ${pkg}_PKG=\"$pkg_filename\"
	export ${pkg}_PKG

	print_ok
}

# write .deb package meta-data
# USAGE: pkg_write_deb
# NEEDED VARS: GAME_NAME PKG_DEPS_DEB
# CALLED BY: write_metadata
pkg_write_deb() {
	local pkg_deps
	if [ "$(eval printf -- '%b' \"\$${pkg}_DEPS\")" ]; then
		pkg_set_deps_deb $(eval printf -- '%b' \"\$${pkg}_DEPS\")
	fi
	use_archive_specific_value "${pkg}_DEPS_DEB"
	if [ "$(eval printf -- '%b' \"\$${pkg}_DEPS_DEB\")" ]; then
		if [ -n "$pkg_deps" ]; then
			pkg_deps="$pkg_deps, $(eval printf -- '%b' \"\$${pkg}_DEPS_DEB\")"
		else
			pkg_deps="$(eval printf -- '%b' \"\$${pkg}_DEPS_DEB\")"
		fi
	fi
	local pkg_size
	pkg_size=$(du --total --block-size=1K --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
	local target
	target="$pkg_path/DEBIAN/control"

	PKG="$pkg"
	get_package_version

	mkdir --parents "${target%/*}"

	cat > "$target" <<- EOF
	Package: $pkg_id
	Version: $PKG_VERSION
	Architecture: $pkg_architecture
	Maintainer: $pkg_maint
	Installed-Size: $pkg_size
	Section: non-free/games
	EOF

	if [ -n "$pkg_provide" ]; then
		cat >> "$target" <<- EOF
		Conflicts: $pkg_provide
		Provides: $pkg_provide
		Replaces: $pkg_provide
		EOF
	fi

	if [ -n "$pkg_deps" ]; then
		cat >> "$target" <<- EOF
		Depends: $pkg_deps
		EOF
	fi

	if [ -n "$pkg_description" ]; then
		cat >> "$target" <<- EOF
		Description: $GAME_NAME - $pkg_description
		 ./play.it script version $script_version
		EOF
	else
		cat >> "$target" <<- EOF
		Description: $GAME_NAME
		 ./play.it script version $script_version
		EOF
	fi

	if [ "$pkg_architecture" = 'all' ]; then
		sed -i 's/Architecture: all/&\nMulti-Arch: foreign/' "$target"
	fi

	if [ -e "$postinst" ]; then
		target="$pkg_path/DEBIAN/postinst"
		cat > "$target" <<- EOF
		#!/bin/sh -e

		$(cat "$postinst")

		exit 0
		EOF
		chmod 755 "$target"
	fi

	if [ -e "$prerm" ]; then
		target="$pkg_path/DEBIAN/prerm"
		cat > "$target" <<- EOF
		#!/bin/sh -e

		$(cat "$prerm")

		exit 0
		EOF
		chmod 755 "$target"
	fi
}

# set list of Debian dependencies from generic names
# USAGE: pkg_set_deps_deb $dep[…]
# CALLED BY: pkg_write_deb
pkg_set_deps_deb() {
	local architecture
	for dep in "$@"; do
		case $dep in
			('alsa')
				pkg_dep='libasound2-plugins'
			;;
			('bzip2')
				pkg_dep='libbz2-1.0'
			;;
			('dosbox')
				pkg_dep='dosbox'
			;;
			('freetype')
				pkg_dep='libfreetype6'
			;;
			('gcc32')
				pkg_dep='gcc-multilib:amd64 | gcc'
			;;
			('gconf')
				pkg_dep='libgconf-2-4'
			;;
			('glibc')
				pkg_dep='libc6'
			;;
			('glu')
				pkg_dep='libglu1-mesa | libglu1'
			;;
			('glx')
				pkg_dep='libgl1-mesa-glx | libgl1'
			;;
			('gtk2')
				pkg_dep='libgtk2.0-0'
			;;
			('json')
				pkg_dep='libjson-c3 | libjson-c2 | libjson0'
			;;
			('libcurl')
				pkg_dep='libcurl4 | libcurl3'
			;;
			('libcurl-gnutls')
				pkg_dep='libcurl3-gnutls'
			;;
			('libstdc++')
				pkg_dep='libstdc++6'
			;;
			('libxrandr')
				pkg_dep='libxrandr2'
			;;
			('nss')
				pkg_dep='libnss3'
			;;
			('openal')
				pkg_dep='libopenal1'
			;;
			('pulseaudio')
				pkg_dep='pulseaudio:amd64 | pulseaudio'
			;;
			('sdl1.2')
				pkg_dep='libsdl1.2debian'
			;;
			('sdl2')
				pkg_dep='libsdl2-2.0-0'
			;;
			('sdl2_image')
				pkg_dep='libsdl2-image-2.0-0'
			;;
			('sdl2_mixer')
				pkg_dep='libsdl2-mixer-2.0-0'
			;;
			('vorbis')
				pkg_dep='libvorbisfile3'
			;;
			('wine')
				use_archive_specific_value "${pkg}_ARCH"
				architecture="$(eval printf -- '%b' \"\$${pkg}_ARCH\")"
				case "$architecture" in
					('32') pkg_set_deps_deb 'wine32' ;;
					('64') pkg_set_deps_deb 'wine64' ;;
				esac
			;;
			('wine32')
				pkg_dep='wine32-development | wine32 | wine-bin | wine-i386 | wine-staging-i386, wine:amd64 | wine'
			;;
			('wine64')
				pkg_dep='wine64-development | wine64 | wine64-bin | wine-amd64 | wine-staging-amd64, wine'
			;;
			('wine-staging')
				use_archive_specific_value "${pkg}_ARCH"
				architecture="$(eval printf -- '%b' \"\$${pkg}_ARCH\")"
				case "$architecture" in
					('32') pkg_set_deps_deb 'wine32-staging' ;;
					('64') pkg_set_deps_deb 'wine64-staging' ;;
				esac
			;;
			('wine32-staging')
				pkg_dep='wine-staging-i386, winehq-staging:amd64 | winehq-staging'
			;;
			('wine64-staging')
				pkg_dep='wine-staging-amd64, winehq-staging'
			;;
			('winetricks')
				pkg_dep='winetricks'
			;;
			('xcursor')
				pkg_dep='libxcursor1'
			;;
			('xft')
				pkg_dep='libxft2'
			;;
			('xgamma'|'xrandr')
				pkg_dep='x11-xserver-utils:amd64 | x11-xserver-utils'
			;;
			(*)
				pkg_dep="$dep"
			;;
		esac
		if [ -n "$pkg_deps" ]; then
			pkg_deps="$pkg_deps, $pkg_dep"
		else
			pkg_deps="$pkg_dep"
		fi
	done
}

# build .deb package
# USAGE: pkg_build_deb $pkg_path
# NEEDED VARS: (OPTION_COMPRESSION) (LANG) PLAYIT_WORKDIR
# CALLS: pkg_print
# CALLED BY: build_pkg
pkg_build_deb() {
	local pkg_filename
	pkg_filename="$PWD/${1##*/}.deb"
	if [ -e "$pkg_filename" ]; then
		pkg_build_print_already_exists "${pkg_filename##*/}"
		eval ${pkg}_PKG=\"$pkg_filename\"
		export ${pkg}_PKG
		return 0
	fi

	local dpkg_options
	case $OPTION_COMPRESSION in
		('gzip'|'none'|'xz')
			dpkg_options="-Z$OPTION_COMPRESSION"
		;;
		(*)
			liberror 'OPTION_COMPRESSION' 'pkg_build_deb'
		;;
	esac

	pkg_print "${pkg_filename##*/}"
	if [ "$DRY_RUN" = '1' ]; then
		printf '\n'
		eval ${pkg}_PKG=\"$pkg_filename\"
		export ${pkg}_PKG
		return 0
	fi
	TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb $dpkg_options --build "$1" "$pkg_filename" 1>/dev/null
	eval ${pkg}_PKG=\"$pkg_filename\"
	export ${pkg}_PKG

	print_ok
}

if [ "${0##*/}" != 'libplayit2.sh' ] && [ -z "$LIB_ONLY" ]; then

	# Check library version against script target version

	version_major_library="${library_version%%.*}"
	version_major_target="${target_version%%.*}"

	version_minor_library=$(printf '%s' "$library_version" | cut --delimiter='.' --fields=2)
	version_minor_target=$(printf '%s' "$target_version" | cut --delimiter='.' --fields=2)

	if [ $version_major_library -ne $version_major_target ] || [ $version_minor_library -lt $version_minor_target ]; then
		print_error
		case "${LANG%_*}" in
			('fr')
				string1='Mauvaise version de libplayit2.sh\n'
				string2='La version cible est : %s\n'
			;;
			('en'|*)
				string1='Wrong version of libplayit2.sh\n'
				string2='Target version is: %s\n'
			;;
		esac
		printf "$string1"
		printf "$string2" "$target_version"
		exit 1
	fi

	# Set allowed values for common options

	ALLOWED_VALUES_ARCHITECTURE='all 32 64 auto'
	ALLOWED_VALUES_CHECKSUM='none md5'
	ALLOWED_VALUES_COMPRESSION='none gzip xz'
	ALLOWED_VALUES_PACKAGE='arch deb'

	# Set default values for common options

	DEFAULT_OPTION_ARCHITECTURE='all'
	DEFAULT_OPTION_CHECKSUM='md5'
	DEFAULT_OPTION_COMPRESSION='none'
	DEFAULT_OPTION_PREFIX='/usr/local'
	DEFAULT_OPTION_PACKAGE='deb'
	unset winecfg_desktop
	unset winecfg_launcher

	# Parse arguments given to the script

	unset OPTION_ARCHITECTURE
	unset OPTION_CHECKSUM
	unset OPTION_COMPRESSION
	unset OPTION_PREFIX
	unset OPTION_PACKAGE
	unset SOURCE_ARCHIVE
	DRY_RUN='0'

	while [ $# -gt 0 ]; do
		case "$1" in
			('--help')
				help
				exit 0
			;;
			('--architecture='*|\
			 '--architecture'|\
			 '--checksum='*|\
			 '--checksum'|\
			 '--compression='*|\
			 '--compression'|\
			 '--prefix='*|\
			 '--prefix'|\
			 '--package='*|\
			 '--package')
				if [ "${1%=*}" != "${1#*=}" ]; then
					option="$(printf '%s' "${1%=*}" | sed 's/^--//')"
					value="${1#*=}"
				else
					option="$(printf '%s' "$1" | sed 's/^--//')"
					value="$2"
					shift 1
				fi
				if [ "$value" = 'help' ]; then
					eval help_$option
					exit 0
				else
					eval OPTION_$(printf '%s' "$option" | tr '[:lower:]' '[:upper:]')=\"$value\"
					export OPTION_$(printf '%s' "$option" | tr '[:lower:]' '[:upper:]')
				fi
				unset option
				unset value
			;;
			('--dry-run')
				DRY_RUN='1'
				export DRY_RUN
			;;
			('--'*)
				print_error
				case "${LANG%_*}" in
					('fr')
						string='Option inconnue : %s\n'
					;;
					('en'|*)
						string='Unkown option: %s\n'
					;;
				esac
				printf "$string" "$1"
				return 1
			;;
			(*)
				SOURCE_ARCHIVE="$1"
				export SOURCE_ARCHIVE
			;;
		esac
		shift 1
	done

	# Try to detect the host distribution if no package format has been explicitely set

	[ "$OPTION_PACKAGE" ] || packages_guess_format 'OPTION_PACKAGE'

	# Set options not already set by script arguments to default values

	for option in 'ARCHITECTURE' 'CHECKSUM' 'COMPRESSION' 'PREFIX'; do
		if [ -z "$(eval printf -- '%b' \"\$OPTION_$option\")" ]\
		&& [ -n "$(eval printf -- \"\$DEFAULT_OPTION_$option\")" ]; then
			eval OPTION_$option=\"$(eval printf -- '%b' \"\$DEFAULT_OPTION_$option\")\"
			export OPTION_$option
		fi
	done

	# Check options values validity

	check_option_validity() {
		local name
		name="$1"
		local value
		value="$(eval printf -- '%b' \"\$OPTION_$option\")"
		local allowed_values
		allowed_values="$(eval printf -- '%b' \"\$ALLOWED_VALUES_$option\")"
		for allowed_value in $allowed_values; do
			if [ "$value" = "$allowed_value" ]; then
				return 0
			fi
		done
		print_error
		local string1
		local string2
		case "${LANG%_*}" in
			('fr')
				string1='%s n’est pas une valeur valide pour --%s.\n'
				string2='Lancez le script avec l’option --%s=help pour une liste des valeurs acceptés.\n'
			;;
			('en'|*)
				string1='%s is not a valid value for --%s.\n'
				string2='Run the script with the option --%s=help to get a list of supported values.\n'
			;;
		esac
		printf "$string1" "$value" "$(printf '%s' $option | tr '[:upper:]' '[:lower:]')"
		printf "$string2" "$(printf '%s' $option | tr '[:upper:]' '[:lower:]')"
		printf '\n'
		exit 1
	}

	for option in 'CHECKSUM' 'COMPRESSION' 'PACKAGE'; do
		check_option_validity "$option"
	done

	# Restrict packages list to target architecture

	select_package_architecture

	# Check script dependencies

	check_deps

	# Set package paths

	case $OPTION_PACKAGE in
		('arch')
			PATH_BIN="$OPTION_PREFIX/bin"
			PATH_DESK='/usr/local/share/applications'
			PATH_DOC="$OPTION_PREFIX/share/doc/$GAME_ID"
			PATH_GAME="$OPTION_PREFIX/share/$GAME_ID"
			PATH_ICON_BASE='/usr/local/share/icons/hicolor'
		;;
		('deb')
			PATH_BIN="$OPTION_PREFIX/games"
			PATH_DESK='/usr/local/share/applications'
			PATH_DOC="$OPTION_PREFIX/share/doc/$GAME_ID"
			PATH_GAME="$OPTION_PREFIX/share/games/$GAME_ID"
			PATH_ICON_BASE='/usr/local/share/icons/hicolor'
		;;
		(*)
			liberror 'OPTION_PACKAGE' "$0"
		;;
	esac

	# Set main archive

	archives_get_list
	archive_set_main $ARCHIVES_LIST

	# Set working directories

	set_temp_directories $PACKAGES_LIST

fi
