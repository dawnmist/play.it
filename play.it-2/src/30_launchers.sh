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
	pkg_path="$(get_value "${PKG}_PATH")"
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
		if [ -n "$(get_value "${app}_ID")" ]; then
			app_id="$(get_value "${app}_ID")"
		else
			app_id="$GAME_ID"
		fi

		use_package_specific_value "${app}_EXE"
		use_package_specific_value "${app}_LIBS"
		use_package_specific_value "${app}_OPTIONS"
		use_package_specific_value "${app}_POSTRUN"
		use_package_specific_value "${app}_PRERUN"
		app_exe="$(get_value "${app}_EXE")"
		app_libs="$(get_value "${app}_LIBS")"
		app_options="$(get_value "${app}_OPTIONS")"
		app_postrun="$(get_value "${app}_POSTRUN")"
		app_prerun="$(get_value "${app}_PRERUN")"
		app_type="$(get_value "${app}_TYPE")"

		if [ "$app_type" = 'native' ] ||\
		   [ "$app_type" = 'native_no-prefix' ]; then
			chmod +x "${pkg_path}${PATH_GAME}/$app_exe"
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
			for dir in "$PATH_PREFIX" "$PATH_CONFIG" "$PATH_DATA"; do
			  if [ ! -e "$dir" ]; then
			    mkdir --parents "$dir"
			  fi
			done
			(
			  cd "$PATH_GAME"
			  find . -type d | while read dir; do
			    if [ -h "$PATH_PREFIX/$dir" ]; then
			      rm "$PATH_PREFIX/$dir"
			    fi
			  done
			)
			cp --recursive --remove-destination --symbolic-link "$PATH_GAME"/* "$PATH_PREFIX"
			(
			  cd "$PATH_PREFIX"
			  find . -type l | while read link; do
			    if [ ! -e "$link" ]; then
			      rm "$link"
			    fi
			  done
			  find . -depth -type d | while read dir; do
			    if [ ! -e "$PATH_GAME/$dir" ]; then
			      rmdir --ignore-fail-on-non-empty "$dir"
			    fi
			  done
			)
			init_userdir_files "$PATH_CONFIG" "$CONFIG_FILES"
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

		app_type="$(get_value "${app}_TYPE")"
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

		if [ -n "$(get_value "${app}_ID")" ]; then
			app_id="$(get_value "${app}_ID")"
		else
			app_id="$GAME_ID"
		fi

		if [ -n "$(get_value "${app}_NAME")" ]; then
			app_name="$(get_value "${app}_NAME")"
		else
			app_name="$GAME_NAME"
		fi

		if [ -n "$(get_value "${app}_CAT")" ]; then
			app_cat="$(get_value "${app}_CAT")"
		else
			app_cat='Game'
		fi

		pkg_path="$(get_value "${PKG}_PATH")"
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

