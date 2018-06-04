# write .ebuild package meta-data
# USAGE: pkg_write_arch
# NEEDED VARS: GAME_NAME PKG_DEPS_GENTOO
# CALLED BY: write_metadata
pkg_write_gentoo() {
	pkg_id="$(printf '%s' "$pkg_id" | sed 's/-/_/g')"

	local pkg_deps
	if [ "$(eval printf -- '%b' \"\$${pkg}_DEPS\")" ]; then
		pkg_set_deps_gentoo $(eval printf -- '%b' \"\$${pkg}_DEPS\")
	fi
	use_archive_specific_value "${pkg}_DEPS_GENTOO"
	if [ "$(eval printf -- '%b' \"\$${pkg}_DEPS_GENTOO\")" ]; then
		pkg_deps="$pkg_deps $(eval printf -- '%b' \"\$${pkg}_DEPS_GENTOO\")"
	fi

	if [ -n "$pkg_provide" ]; then
		for package in $PACKAGES_LIST; do
			if [ "$package" != "$pkg" ]; then
				use_archive_specific_value "${package}_PROVIDE"
				local provide="$(eval printf -- '%b' \"\$${package}_PROVIDE\")"
				if [ "$provide" = "$pkg_provide" ]; then
					use_archive_specific_value "${pkg}_ID"
					local package_id="$(eval printf -- '%b' \"\$${package}_ID\")"
					pkg_deps="$pkg_deps !!games-playit/$package_id"
				fi
			fi
		done
	fi

	PKG="$pkg"
	get_package_version

	mkdir --parents \
		"$PLAYIT_WORKDIR/gentoo-overlay/metadata" \
		"$PLAYIT_WORKDIR/gentoo-overlay/profiles" \
		"$PLAYIT_WORKDIR/gentoo-overlay/games-playit/$pkg_id/files"
	echo 'masters = gentoo steam-overlay' > "$PLAYIT_WORKDIR/gentoo-overlay/metadata/layout.conf"
	echo 'games-playit' > "$PLAYIT_WORKDIR/gentoo-overlay/profiles/categories"
	ln --symbolic --force --no-target-directory "$pkg_path" "$PLAYIT_WORKDIR/gentoo-overlay/games-playit/$pkg_id/files/install"
	local target
	target="$PLAYIT_WORKDIR/gentoo-overlay/games-playit/$pkg_id/$pkg_id-${PKG_VERSION%-*}.ebuild"

	cat > "$target" <<- EOF
	EAPI=6
	EOF
	local pkg_architectures
	set_supported_architectures "$PKG"
	cat >> "$target" <<- EOF
	KEYWORDS="$pkg_architectures"
	EOF

	if [ -n "$pkg_description" ]; then
		cat >> "$target" <<- EOF
		DESCRIPTION="$GAME_NAME - $pkg_description - ./play.it script version $script_version"
		EOF
	else
		cat >> "$target" <<- EOF
		DESCRIPTION="$GAME_NAME - ./play.it script version $script_version"
		EOF
	fi

	cat >> "$target" <<- EOF
	SLOT="0"
	EOF

	cat >> "$target" <<- EOF
	RDEPEND="$pkg_deps"

	src_unpack() {
		mkdir -p "\$S"
	}
	src_install() {
		cp -R \$FILESDIR/install/* \$D/
	}
	EOF

	#if [ -n "$pkg_provide" ]; then
	#	cat >> "$target" <<- EOF
	#	conflict = $pkg_provide
	#	provides = $pkg_provide
	#	EOF
	#fi

	if [ -e "$postinst" ]; then
		cat >> "$target" <<- EOF
		pkg_postinst() {
		$(cat "$postinst")
		}
		EOF
	fi

	if [ -e "$prerm" ]; then
		cat >> "$target" <<- EOF
		pkg_prerm() {
		$(cat "$prerm")
		}
		EOF
	fi
}

# set list or Gentoo Linux dependencies from generic names
# USAGE: pkg_set_deps_gentoo $dep[…]
# CALLS: pkg_set_deps_gentoo32 pkg_set_deps_gentoo64
# CALLED BY: pkg_write_gentoo
pkg_set_deps_gentoo() {
	use_archive_specific_value "${pkg}_ARCH"
	local architecture
	architecture="$(eval printf -- '%b' \"\$${pkg}_ARCH\")"
	local architecture_suffix
	case $architecture in
		('32')
			architecture_suffix='[abi_x86_32]'
		;;
		('64')
			architecture_suffix=''
		;;
	esac
	for dep in "$@"; do
		case $dep in
			('alsa')
				pkg_dep="media-libs/alsa-lib$architecture_suffix media-plugins/alsa-plugins$architecture_suffix"
			;;
			('bzip2')
				pkg_dep="app-arch/bzip2$architecture_suffix"
			;;
			('dosbox')
				pkg_dep="games-emulation/dosbox"
			;;
			('freetype')
				pkg_dep="media-libs/freetype$architecture_suffix"
			;;
			('gcc32')
				pkg_dep='' #gcc (in @system) should be multilib unless it is a no-multilib profile, in which case the 32 bits libraries wouldn't work
			;;
			('gconf')
				pkg_dep="gnome-base/gconf$architecture_suffix"
			;;
			('glibc')
				pkg_dep="sys-libs/glibc amd64? ( sys-libs/glibc[multilib] )" #TODO: check if it works
			;;
			('glu')
				pkg_dep="virtual/glu$architecture_suffix"
			;;
			('glx')
				pkg_dep="virtual/opengl$architecture_suffix"
			;;
			('gtk2')
				pkg_dep="x11-libs/gtk+:2$architecture_suffix"
			;;
			('json')
				pkg_dep="dev-libs/json-c$architecture_suffix"
			;;
			('libcurl-gnutls')
				pkg_dep="net-libs/libcurl-debian$architecture_suffix" #available in the steam overlay
			;;
			('libstdc++')
				pkg_dep='' #maybe this should be virtual/libstdc++, otherwise, it is included in gcc, which should be in @system
			;;
			('libxrandr')
				pkg_dep="x11-libs/libXrandr$architecture_suffix"
			;;
			('nss')
				pkg_dep="dev-libs/nss$architecture_suffix"
			;;
			('openal')
				pkg_dep="media-libs/openal$architecture_suffix"
			;;
			('pulseaudio')
				pkg_dep='media-sound/pulseaudio' #TODO: maybe apulse could work too
			;;
			('sdl1.2')
				pkg_dep="media-libs/libsdl$architecture_suffix"
			;;
			('sdl2')
				pkg_dep="media-libs/libsdl2$architecture_suffix"
			;;
			('sdl2_image')
				pkg_dep="media-libs/sdl2-image$architecture_suffix"
			;;
			('sdl2_mixer')
				pkg_dep="media-libs/sdl2-mixer$architecture_suffix"
			;;
			('vorbis')
				pkg_dep="media-libs/libvorbis$architecture_suffix"
			;;
			('wine')
				use_archive_specific_value "${pkg}_ARCH"
				architecture="$(eval printf -- '%b' \"\$${pkg}_ARCH\")"
				case "$architecture" in
					('32') pkg_set_deps_gentoo 'wine32' ;;
					('64') pkg_set_deps_gentoo 'wine64' ;;
				esac
			;;
			('wine32')
				 pkg_dep='virtual/wine[abi_x86_32]'
			;;
			('wine64')
				pkg_dep='vîrtual/wine[abi_x86_64]'
			;;
			('winetricks')
				pkg_dep="app-emulation/winetricks$architecture_suffix"
			;;
			('xcursor')
				pkg_dep="x11-libs/libXcursor$architecture_suffix"
			;;
			('xft')
				pkg_dep="x11-libs/libXft$architecture_suffix"
			;;
			('xgamma')
				pkg_dep="x11-apss/xgamma$architecture_suffix"
			;;
			('xrandr')
				pkg_dep="x11-apps/xrandr$architecture_suffix"
			;;
			(*)
				pkg_dep=''
				local has_provides=false
				for pkg in $PACKAGES_LIST; do
					use_archive_specific_value "${pkg}_PROVIDE"
					local provide="$(eval printf -- '%b' \"\$${pkg}_PROVIDE\")"
					if [ "$provide" = "$dep" ]; then
						has_provides=true
						use_archive_specific_value "${pkg}_ID"
						local pkg_id="$(eval printf -- '%b' \"\$${pkg}_ID\" | sed 's/-/_/g')"
						pkg_dep="$pkg_dep games-playit/$pkg_id"
					fi
				done
				if [ "$has_provides" != true ]; then
					pkg_dep='games-playit/'"$(printf '%s' "$dep" | sed 's/-/_/g')"
				else
					pkg_dep="|| ($pkg_dep )"
				fi
			;;
		esac
		pkg_deps="$pkg_deps $pkg_dep"
	done
}

# build .tbz2 gentoo package
# USAGE: pkg_build_gentoo $pkg_path
# NEEDED VARS: (LANG) PLAYIT_WORKDIR
# CALLS: pkg_print
# CALLED BY: build_pkg
pkg_build_gentoo() {
	local pkg_filename
	pkg_filename="$PWD/${1##*/}.tbz2"

	if [ -e "$pkg_filename" ]; then
		pkg_build_print_already_exists "${pkg_filename##*/}"
		eval ${pkg}_PKG=\"$pkg_filename\"
		export ${pkg}_PKG
		return 0
	fi

	pkg_print "${pkg_filename##*/}"
	if [ "$DRY_RUN" = '1' ]; then
		printf '\n'
		eval ${pkg}_PKG=\"$pkg_filename\"
		export ${pkg}_PKG
		return 0
	fi

	mkdir --parents "$PLAYIT_WORKDIR/portage-tmpdir"
	pkg_id="$(eval printf -- '%b' \"\$${pkg}_ID\" | sed 's/-/_/g')"
	local ebuild_path="$PLAYIT_WORKDIR/gentoo-overlay/games-playit/$pkg_id/$pkg_id-${PKG_VERSION%-*}.ebuild"
	ebuild "$ebuild_path" manifest
	PORTAGE_TMPDIR="$PLAYIT_WORKDIR/portage-tmpdir" PKGDIR="$PLAYIT_WORKDIR/gentoo-pkgdir" fakeroot-ng -- ebuild "$ebuild_path" package
	mv "$PLAYIT_WORKDIR/gentoo-pkgdir/games-playit/$pkg_id-${PKG_VERSION%-*}.tbz2" "$pkg_filename"
	rm -r "$PLAYIT_WORKDIR/portage-tmpdir"

	eval ${pkg}_PKG=\"$pkg_filename\"
	export ${pkg}_PKG

	print_ok
}

