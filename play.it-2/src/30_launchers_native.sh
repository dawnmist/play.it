# write launcher script - set native game common vars (no prefix)
# USAGE: write_bin_set_native_noprefix
# CALLED BY: write_bin
write_bin_set_native_noprefix() {
	local library_path="$app_libs"
	if [ "$OPTION_PACKAGE" = 'gentoo' ]; then # Add debiancompat directory to LD_LIBRARY_PATH if necessary
		local pkg_architecture
		set_architecture_single "$PKG"
		library_path="$library_path:\$(portageq envvar LIBDIR_$pkg_architecture)/debiancompat"
	fi
	library_path="$library_path:\$LD_LIBRARY_PATH"
	cat >> "$file" <<- EOF
	# Set executable file

	APP_EXE='$app_exe'
	APP_OPTIONS="$app_options"
	LD_LIBRARY_PATH="$library_path"
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

