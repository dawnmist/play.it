# set distribution-specific package architecture for Gentoo Linux target
# Usage set_architecture_gentoo $architecture
# CALLED BY: set_architecture
set_architecture_gentoo() {
	case "$1" in
		('32')
			pkg_architecture='x86 amd64'
		;;
		('64')
			pkg_architecture='amd64'
		;;
		(*)
			pkg_architecture='x86 amd64' #data packages
		;;
	esac
}
# set distribution-specific single package architecture for Gentoo Linux target
# Usage set_architecture_gentoo_single $architecture
# CALLED BY: set_architecture_single
set_architecture_gentoo_single() {
	case "$1" in
		('32')
			pkg_architecture='x86'
		;;
		('64')
			pkg_architecture='amd64'
		;;
		(*)
			#TODO: what should I put here
		;;
	esac
}
