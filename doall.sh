#!/bin/bash -e


links(){
	cat <<EOF
https://github.com/tihmstar/libgeneral.git
https://github.com/tihmstar/libfragmentzip.git
https://github.com/libimobiledevice/libplist.git
https://github.com/libimobiledevice/libimobiledevice-glue.git
https://github.com/libimobiledevice/libusbmuxd.git
https://github.com/libimobiledevice/libirecovery.git
https://github.com/libimobiledevice/libimobiledevice.git
https://github.com/nih-at/libzip.git
https://github.com/1Conan/tsschecker.git

https://github.com/lzfse/lzfse.git
https://github.com/tihmstar/img4tool.git
https://github.com/tihmstar/libinsn.git
https://github.com/tihmstar/liboffsetfinder64.git
https://github.com/planetbeing/xpwn.git
https://github.com/Cryptiiiic/libipatcher.git
https://github.com/Arna13/futurerestore.git

https://github.com/tihmstar/igetnonce.git
https://github.com/tihmstar/noncestatistics.git
EOF
}

install_xpwn(){
	cp -R includes/* $ROOT/INST/include/
	cp common/*.a ipsw-patch/*.a $ROOT/INST/lib/
}

log_run(){
	LOGFILE="$1"
	shift
	echo $'\x1b[1;31m' "$@" $'\x1b[0m' >&2
	if [ $(uname -s) = "Linux" ] ; then
		script -q "$LOGFILE" -ec "$*" >/dev/null 2>&1 || {
			cat $LOGFILE
			false
		}
	else
		script -q "$LOGFILE" "$@" >/dev/null 2>&1 || {
			cat $LOGFILE
			false
		}
	fi
}

cfgopts(){
	case "$1" in
		libplist) echo "--without-cython" ;;
		libipatcher)
			if [ $(uname -s) = "Linux" ] ; then
				echo "--without-iBoot64Patcher"
			fi
			;;
		xpwn) echo "-DCMAKE_C_FLAGS_INIT=-fPIC" ;;
		*) true ;;
	esac
}

install_opts(){
	if [ "$1" = "libirecovery" ] ; then
		mkdir -p $ROOT/INST/udev
		echo "udevrulesdir=$ROOT/INST/udev"
	fi
}

# libgeneral uses commit count as a version. so must get all the history.
gitopts(){
	case "$1" in 
		libgeneral | libfragmentzip | libinsn | img4tool | liboffsetfinder64 | libipatcher | igetnonce )
			true ;;
		*)
			echo "--depth 1" ;;
	esac
}

hook-build(){
	if [ $(uname -s) = "Linux" ] ; then
		case "$1" in
			libinsn|liboffsetfinder64)
				touch .sw-installed
				;;
		esac
	fi
}

do_build(){
	if [ ! -d "$1" ] ; then
		git clone $(gitopts $1) --recursive "$2"
		if [ -f _patches/$1.patch ] ; then
			(cd "$1" ; patch -p1 < ../_patches/$1.patch)
		fi
	fi
	pushd "$1" >/dev/null
	hook-build "$1"
	if [ -f .sw-installed ]; then
		popd >/dev/null
		return
	fi
	echo "[1;32mBuilding $1[0m" >&2
	git pull > /dev/null || true
	
	if [ ! -f .sw_configed ] ; then
		if [ -e configure ] ; then
			log_run sw_cfg.log ./configure --prefix=$ROOT/INST $(cfgopts $1)
		elif [ -e autogen.sh ] ; then
			log_run sw_cfg.log ./autogen.sh --prefix=$ROOT/INST $(cfgopts $1)
		elif [ -f CMakeLists.txt ] ;then
			log_run sw_cfg.log cmake -DCMAKE_INSTALL_PREFIX:PATH=$ROOT/INST $(cfgopts $1) .
		else
			echo "Unknown maker" >&2
			false
			popd
			exit 1
		fi
		if [ -f Makefile ] ; then
			touch .sw_configed
		fi
	fi

	log_run sw_make.log make -j12

	if [ "$1" = "xpwn" ] ; then
		# install for xpwn is broken
		install_xpwn
	else
		log_run sw_inst.log make $(install_opts $1) install
	fi

	touch .sw-installed
	popd > /dev/null
}

makeall(){
	ROOT=`pwd`
	mkdir -p "$ROOT/INST"
	export PKG_CONFIG_PATH=$ROOT/INST/lib/pkgconfig
	export LD_LIBRARY_PATH=$ROOT/INST/lib
	export LDFLAGS=-L$ROOT/INST/lib
	export CFLAGS=-I$ROOT/INST/include
	export CXXFLAGS=-I$ROOT/INST/include

	for i in $(links) ; do
		do_build $(basename $i .git) $i
	done
}

clean_all(){
	for i in $(links) ; do
		rm -fr $(basename $i .git)
	done
	rm -fr INST
}

dry_del_usrlocal(){
	for i in $(links) ; do
		NAME=$(basename $i .git)
		find /usr/local -name "*$NAME*"
	done
}

if [ "$1" = "dry_del_usrlocal" ] ; then
	dry_del_usrlocal
elif [ "$1" = "clean" ] ; then
	clean_all
else
	makeall
fi
