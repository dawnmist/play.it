# set distribution-specific package architecture for Gentoo Linux target
# Usage set_architecture_gentoo $architecture
# CALLED BY: set_architecture
set_architecture_gentoo() {
	case "$1" in
		('32')
			pkg_architecture='x86'
		;;
		('64')
			pkg_architecture='amd64'
		;;
		(*)
			pkg_architecture='data' # We could put anything here, it shouldn't be used for package metadata
		;;
	esac
}
# set distribution-specific supported architectures for Gentoo Linux target
# Usage set_supported_architectures_gentoo $architecture
# CALLED BY: set_supported_architectures
set_supported_architectures_gentoo() {
	case "$1" in
		('32')
			pkg_architectures='-* x86 amd64'
		;;
		('64')
			pkg_architectures='-* amd64'
		;;
		(*)
			pkg_architectures='x86 amd64' #data packages
		;;
	esac
}
