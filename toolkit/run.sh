#!/bin/bash
ar=aarch64
al=arm64

#p=/data/media/0/pctool
p=/data/data/com.termux/files/home/pctool
d=/ennorath/imladris/src/local/share/meta

t=aarch64-linux-gnu
#t=aarch64-linux-gnueabi
b=x86_64-linux-gnu

f0="--prefix=$p --disable-multilib --disable-profile --disable-nls --disable-werror --disable-sim --disable-threads --disable-lto --disable-host-shared" # --disable-static --disable-threads --disable-sim
f2="--disable-multiarch" # --enable-plugins
f3="--host=$b"
f4="--build=$b --host=$t"
f5="--target=$t"
f1="$f4 $f5 $f0"
fp0="$f1 $f2"
fp1="$f1 $f2 --without-headers --enable-languages=c,c++"
fp2="$f1 --host=$t --with-headers=$p/include libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes --without-gd --enable-addons=no --without-cvs --with-elf --disable-multi-arch" #--without-tls --disable-versioning --disable-sanity-checks

set -e


rmc(){
	[ -z "$1" ] && return
	rm -rf $d/toolkit/$1
	mkdir -p $d/toolkit/$1
	cd $d/toolkit/$1
}

doo(){
	[ -z "$1" ] && return
	case "$1" in
		clean)
			mkdir -p "$p"
			rm -rf "$p"/*
		;;
		linux)
			pushd $d/linux
			make BUILD_CROSS_COMPILE= CROSS_COMPILE= ARCH=$al INSTALL_HDR_PATH=$p headers_install
			popd
		;;
		all)
			doo clean linux binutils gcc glibc libgcc glibcz
		;;
		libgcc)
			make -C toolkit/gcc -j9 all-target-libgcc
			make -C toolkit/gcc install-target-libgcc
		;;
		glibcz)
			make -C toolkit/glibc -j9
			make -C toolkit/glibc install
		;;
		*)
			rmc "$1"
			case "$1" in
				binutils)
					../../binutils-gdb/configure $f $fp0
					make -j9
					make install
					;;
				
				gcc)
					../../gcc/configure $f $fp1
					make -j9 all-gcc
					make install-gcc
					;;
				glibc)
					../../glibc/configure $fp2
					make install-bootstrap-headers=yes install-headers
					make -j9 csu/subdir_lib
					mkdir -p $d/$t/lib
					install csu/crt1.o csu/crti.o csu/crtn.o $d/$t/lib/
					$t-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $d/$t/lib/libc.so
					mkdir -p $d/$t/include/gnu
					touch $d/$t/include/gnu/stubs.h
					;;
			esac
			cd $d
		;;
	esac
	shift
	doo "$@"
}
doo "$@"
