#!/bin/bash
set -e
d=/ennorath/imladris/src/local/share/meta/toolkit/local
z=/ennorath/imladris/src/local/share/meta/zlib
dlin=$d/../../linux
de=$d/exe
dl=$d/lib
v=um
#v=pc
o=/xc/$v
ob=$o/bin
ol=$o/lib
t=x86_64-$v-linux-gnu
f="-O2 -g -Wl,-rpath,$ol"
mm="make -j9"
m="make"
mml="$mm -C $dl"
ml="$m -C $dl"
mme="$mm -C $de"
me="$m -C $de"
mn="$m -C $dlin"

# if false ; then
preclean(){
	rm -rf $o/* $d/{exe,lib}
	mkdir -p $d/{exe,lib}
	pushd "$z"
	#./configure --shared --prefix=$o
	#make all install
	#./configure --static --prefix=$o
	#make all install
	popd
}

headers(){
	#make -C /ennorath/imladris/src/local/share/meta/linux ARCH=x86_64 INSTALL_HDR_PATH=$o headers_install
	$mn ARCH=x86_64 INSTALL_HDR_PATH=$o headers_install
}

bininit(){
	cd $de
	../tree/configure --with-sysroot=$o --prefix=$o --target=$t --disable-{nls,werror,shared,decimal-float,threads,lib{atomic,gomp,mpx,quadmath,ssp,vtv,stdcxx}} --with-glibc-version=2.11 --with-newlib --without-headers --with-local-prefix=$o --with-native-system-header-dir=$o/include --with-lib-path=$ol --enable-languages=c,c++
	#../tree/configure --prefix=$o --disable-{profile,checking,bootstrap,werror,multi{lib,arch},lib{gomp,ssp,quadmath,mpx,vtv,cilkrts,itm,atomic}} --enable-{gnu-{indirect-function,unique-object},shared} --with-native-system-header-dir=$o/include --with-system-zlib --enable-__cxa_atexit --enable-version-specific-runtime-libs --with-slibdir=/$ol 
	#../tree/configure --prefix=$o --disable-{bootstrap,werror,multi{lib,arch},lib{gomp,ssp,atomic,mpx,sanitizer,vtv,cilkrts,itm},static} --enable-{gnu-{indirect-function,unique-object},languages=c} --build=$t C{,XX}FLAGS="$f" --with-native-system-header-dir=$o/include
	$mme all
	$me install
}
libcheader(){
	cd $dl
	../../../glibc/configure --prefix=$o --host=$t --build=x86_64-pc-linux-gnu --enable-kernel=3.2 --with-headers=$o/include --disable-{werror,multilib} libc_cv_{c_cleanup,forced_unwind}=yes
	return
	#BUILD_CC="gcc" CC="$ob/gcc" CXX="$ob/g++" AR="$ob/ar" RANLIB="$ob/ranlib" ../../../glibc/configure --disable-{werror,multi{lib,-arch}} --with-{elf,tls,__thread,headers=$o/include} --enable-{add-ons,kernel=4.14} --prefix=$o libc_cv_{{c_cleanup,forced_unwind}=yes,slibdir=$o/lib}
	#BUILD_CC="gcc" CC="$ob/gcc" CXX="$ob/g++" AR="$ob/ar" RANLIB="$ob/ranlib" ../../../glibc/configure --disable-{werror,multi{lib,-arch}} --with-{elf,tls,__thread,headers=$o/include} --enable-{add-ons,kernel=4.14,shared} --prefix=$o libc_cv_{{c_cleanup,forced_unwind}=yes,slibdir=$o/lib} --{build,host}=$t C{,XX}FLAGS="$f"
	#BUILD_CC="gcc" CC="$ob/gcc" CXX="$ob/g++" AR="$ob/ar" RANLIB="$ob/ranlib" ../../../glibc/configure --disable-{werror,multi{lib,-arch}} --with-{elf,tls,__thread,headers=$o/include} --enable-{add-ons,kernel=4.14,shared,static} --prefix=$o libc_cv_{{c_cleanup,forced_unwind}=yes,slibdir=$o/lib} --{build,host}=$t C{,XX}FLAGS="$f"
 	$ml install-bootstrap-headers=yes install-headers 
	$mml csu/subdir_lib 
	mkdir $dl/lib
	install csu/crt?.o lib 
	$ob/gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $dl/lib/libc.so 
	mkdir -p $o/{,$t/}{lib,include/gnu}
	cp -r $dl/lib/* $o/lib 
	cp -r $dl/lib/* $o/$t/lib 
	touch $o/include/gnu/stubs.h 
	touch $o/$t/include/gnu/stubs.h 
}

libgcc(){
	$mme all-target-libgcc
	$me install-target-libgcc
}

glibc(){
	cd $d/lib
	#BUILD_CC="gcc" CC="$ob/gcc" CXX="$ob/g++" AR="$ob/ar" RANLIB="$ob/ranlib" ../../../glibc/configure --disable-{werror,multi{lib,-arch}} --with-{elf,tls,__thread,headers=$o/include} --enable-{add-ons,kernel=4.14,shared,static} --prefix=$o libc_cv_{{c_cleanup,forced_unwind}=yes,slibdir=$o/lib} --{build,host}=$t C{,XX}FLAGS="$f"
	BUILD_CC="gcc" CC="$ob/gcc" CXX="$ob/g++" AR="$ob/ar" RANLIB="$ob/ranlib" ../../../glibc/configure --disable-{werror,multilib} --with-headers=$o/include --enable-kernel=4.14 --prefix=$o libc_cv_{c_cleanup,forced_unwind}=yes
	#BUILD_CC="gcc" CC="$ob/gcc" CXX="$ob/g++" AR="$ob/ar" RANLIB="$ob/ranlib" ../../../glibc/configure --disable-{werror,multi{lib,-arch}} --with-{elf,tls,__thread,headers=$o/include} --enable-{add-ons,kernel=4.14,shared} --prefix=$o libc_cv_{{c_cleanup,forced_unwind}=yes,slibdir=$o/lib} --{build,host}=$t C{,XX}FLAGS="$f"
	$mml
	$ml install
}

#rm -rf $d/exe
gcc(){
	pushd $de
	../tree/configure --prefix=$o --disable-{multilib,lib{gomp,ssp,quadmath,mpx,vtv,cilkrts,itm,atomic}} --without-headers --with-system-zlib --with-lib-path=$ol --enable-languages=c
	../tree/configure --prefix=$o --disable-{profile,checking,bootstrap,werror,multilib,lib{gomp,ssp,quadmath,mpx,vtv,cilkrts,itm,atomic}} --enable-{indirect-function,unique-object}  --with-native-system-header-dir=$o/include --with-system-zlib --enable-__cxa_atexit --enable-version-specific-runtime-libs  
	#../tree/configure --prefix=$o --disable-{dlopen,profile,checking,bootstrap,werror,multi{lib,arch},lib{gomp,ssp,quadmath,mpx,vtv,cilkrts,itm,atomic}} --enable-{gnu-{indirect-function,unique-object},shared} --build=$t C{,XX}FLAGS="$f" --with-native-system-header-dir=$o/include --with-system-zlib --enable-__cxa_atexit --enable-version-specific-runtime-libs --with-slibdir=/$ol --with-gnu-{as,ld} 
	popd
	$mme
	$me install
}
steps(){
	[ -n "$1" ] || return
	case "$1" in
		0) preclean ;;
		1) headers ;;
		2) bininit ;;
		3) libcheader ;;
		4) libgcc ;;
		5) glibc ;;
		6) gcc ;;
		*) echo wat ;;
	esac
	shift
	steps "$@"
}
steps "$@" |& tee $d/log




