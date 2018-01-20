APP=pwn
TGT=$(shell uname -m)-xc-linux-gnu
PRE0=/$(APP)0
bin0=$(PRE0)/bin
cc0=$(bin0)/$(TGT)-
LC_ALL=POSIX
LANG=C
CFLAGS=-O3 -g -march=native
STAGES=0 1
export PATH:=$(bin0):$(PATH)
comma:=,

$(info $(shell which gcc))

ALLSETS=$(foreach stage,$(STAGES),$(foreach pkg,$(PKG$(stage)),$(stage)/$(pkg)))
ALLSTAGE=$(addprefix stage/,$(ALLSETS))
ALLMAKED=$(addprefix build/,$(ALLSETS))
ALLDONE=$(addsuffix -done,$(addprefix build/,$(ALLSETS)))
ALLSTDONE=$(addsuffix /stamp-done,$(addprefix build/done/,$(ALLSETS)))
ALLMAKEP=$(addsuffix /stamp-made,$(addprefix build/done/,$(ALLSETS)))
ALLDIRMADE=$(addsuffix /stamp-dir-made,$(ALLMAKED))
ALLMAKE=$(addsuffix /Makefile,$(ALLMAKED))
ALLCONF=$(foreach stage,$(STAGES),$(foreach pkg,$(PKG$(stage)),$(pkg)/configure))

.SUFFIXES:

PKG0=binutils-gdb gcc

PKG1=glibc libstdc++-v3 binutils-gdb gcc tcl expect dejagnu check ncurses bash bison bzip2 coreutils diffutils file findutils gawk gettext grep gzip m4 make patch perl sed tar texinfo util-linux xz

configure: $(wildcard */configure)

build: stage/0 stage/1 #$(ALLMAKE) $(ALLSTAGE)

.PHONY: build stage/0 # $(ALLMAKEP)

define _confgg = 
	mkdir -p $(1) && cd $(1) && $(3) $(4)
endef
define _confg = 
	$(call _confgg,$(1),$(2),$(3)/$(patsubst build/$(2)/%,%,$(1))/configure,$(4))
endef
define _conf0 = 
	$(call _confg,$(1),0,../../..,$(2))
endef
define _conf1 = 
	$(call _confg,$(1),1,../../..,$(2))
endef

stageno=$(firstword $(subst /," ",$(patsubst stage/%,%,$1),$1))
stagename=$(patsubst stage/$(call stageno,$1)/%,%,$1)

$(ALLMAKE): %/Makefile : %/stamp-dir-made

$(ALLDIRMADE): 
	mkdir -p $(@D)
	touch $(@D)/stamp-dir-made

$(filter-out expect,$(ALLDONE)): build/%-done : build/done/%/stamp-done 

$(filter-out expect,$(ALLSTDONE)): build/done/%/stamp-done : build/done/%/stamp-made
	mkdir -p build/done/$*
	touch build/done/$*/stamp-done

$(ALLMAKEP): build/done/%/stamp-made : build/%/Makefile
	$(MAKE) -C build/$* all 
	mkdir -p build/done/$* && $(MAKE) -C build/$* DESTDIR=$(CURDIR)/build/dest/$* install 
	$(MAKE) -C build/$* install
	touch build/done/$*/stamp-made

linux/configure build/0/linux/Makefile:
	echo $@ $*

stage/0: $(addprefix stage/0/,setup $(PKG0) linux)
stage/0/setup: build/done/0/setup-done 
stage/0/binutils-gdb: stage/0/setup
stage/0/gcc: stage/0/binutils-gdb
stage/0/linux: stage/0/gcc $(PRE0)/include/linux/.install

stage/1: stage/0 $(addprefix stage/1/,$(PKG1))
stage/1/glibc: stage/0/linux
stage/1/libstdc++-v3: stage/1/glibc 
stage/1/binutils-gdb: stage/1/libstdc++-v3
stage/1/gcc: stage/1/binutils-gdb
stage/1/tcl: stage/1/gcc
stage/1/expect: stage/1/tcl
stage/1/dejagnu: stage/1/expect
stage/1/check: stage/1/dejagnu
stage/1/ncurses: stage/1/gcc
stage/1/bash: stage/1/ncurses
#stage/1/tcl: build/1/tcl/Makefile

build/done/0/setup-done: | $(PRE0)
	su -c 'mkdir -p $(PRE0) ; chown -R meta:meta $(PRE0)'
	mkdir -p build/done/0
	touch build/done/0/setup-done

build/0/binutils-gdb/Makefile:
	$(call _conf0,$(@D),\
		--prefix=$(PRE0) \
		--with-sysroot=$(PRE0) \
		--with-lib-path=/lib \
		--target=$(TGT) \
		--disable-nls \
		--disable-werror )

build/0/gcc/Makefile:
	$(call _conf0,$(@D),\
		--target=$(TGT) \
		--prefix=$(PRE0) \
		--with-glibc-version=2.11 \
		--with-sysroot=/ \
		--with-newlib \
		--without-headers \
		--with-local-prefix=$(PRE0) \
		--with-native-system-header-dir=$(PRE0)/include \
		--disable-nls \
		--disable-shared \
		--disable-multilib \
		--disable-decimal-float \
		--disable-threads \
		--disable-werror \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libmpx \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libvtv \
		--disable-libstdcxx \
		--disable-bootstrap \
		--enable-languages=c$(comma)c++ )

$(PRE0)/include/linux/.install:
	$(MAKE) -C linux INSTALL_HDR_PATH=$(PRE0) headers_install

build/1/glibc/Makefile:
	$(call _conf1,$(@D),\
		--prefix=$(PRE0) \
		--with-binutils=$(bin0) \
		--disable-multilib \
		--build=$(TGT) \
		--host=x86_64-pc-linux-gnu \
		--enable-kernel=3.2 \
		--with-headers=$(PRE0)/include \
		libc_cv_forced_unwind=yes \
		libc_cv_c_cleanup=yes )

build/done/1/libstdc++-v3/stamp-done: $(PRE0)/$(TGT)/include/c++/7.2.0/cstdlib
$(PRE0)/$(TGT)/include/c++/7.2.0/cstdlib: build/done/1/libstdc++-v3/stamp-made
libstdc++-v3/configure: gcc/libstdc++-v3/configure
build/1/libstdc++-v3/Makefile:
	$(call _confg,$(@D),1,../../../gcc, \
		CFLAGS="$(or $(CFLAGS),-O2)" \
		CXXFLAGS="$(or $(CXXFLAGS),-O2)" \
		--host=$(TGT) \
		--prefix=$(PRE0) \
		--with-sysroot=$(PRE0) \
		--disable-multilib \
		--disable-nls \
		--disable-libstdcxx-threads \
		--disable-libstdcxx-pch \
		--with-gxx-include-dir=$(PRE0)/$(TGT)/include/c++/7.2.0 )

build/1/binutils-gdb/Makefile:
	$(call _conf1,$(@D),\
		CC=$(cc0)gcc \
		AR=$(cc0)ar \
		RANLIB=$(cc0)ranlib \
		--prefix=$(PRE0) \
		--disable-nls \
		--disable-werror \
		--with-lib-path=$(PRE0)/lib \
		--with-sysroot )

build/done/1/binutils-gdb/stamp-done: $(bin0)/ld-new
$(bin0)/ld-new: build/done/1/binutils-gdb/stamp-made build/1/binutils-gdb/ld/ld-new
	$(MAKE) -C build/1/binutils-gdb/ld clean
	$(MAKE) -C build/1/binutils-gdb/ld LIB_PATH=$(PRE0)/lib:/usr/lib:/lib
	cp -v build/1/binutils-gdb/ld/ld-new $(PRE0)/bin


build/1/gcc/Makefile: 
	cd gcc/gcc && cat limitx.h glimits.h limity.h > \
		$(dir $(shell $(cc0)gcc -print-libgcc-file-name))include-fixed/limits.h
	$(call _conf1,$(@D),\
		CC=$(TGT)-gcc \
		CXX=$(TGT)-g++ \
		AR=$(TGT)-ar \
		RANLIB=$(TGT)-ranlib \
		--prefix=$(PRE0) \
		--with-local-prefix=$(PRE0) \
		--with-native-system-header-dir=$(PRE0)/include \
		--enable-languages=c$(comma)c++ \
		--disable-libstdcxx-pch \
		--disable-multilib \
		--disable-bootstrap \
		--disable-libgomp )

tcl/configure: tcl/unix/configure
build/1/tcl/Makefile: tcl/configure
	$(call _confgg,$(@D),1,../../../tcl/unix/configure,--prefix=$(PRE0))
	$(MAKE) -C build/1/tcl all install
	chmod -v u+w $(PRE0)/lib/libtcl8.*
	$(MAKE) -C build/1/tcl install-private-headers
	[ -f $(bin0)/tclsh ] || ( cd $(bin0) && ln -sv tclsh8.* $(bin0)/tclsh )

expect/configure.$(APP): expect/configure
	cd expect && \
	cp -v configure configure.$(APP) && \
	sed 's:/usr/local/bin:$(PRE0)/bin:' configure.$(APP) > configure

build/1/expect/Makefile: expect/configure.$(APP)
	$(call _conf1,$(@D),\
		--prefix=$(PRE0) \
		--with-tcl=$(PRE0)/lib \
		--with-tclinclude=$(PRE0)/include )

build/done/1/expect-made : build/1/expect/Makefile
	$(MAKE) -C build/1/expect all 
	mkdir -p build/done/1/expect && $(MAKE) -C build/1/expect DESTDIR=$(CURDIR)/build/dest/1/expect SCRIPTS="" install 
	$(MAKE) -C build/1/expect SCRIPTS="" install

build/1/dejagnu/Makefile:
	$(call _conf1,$(@D),--prefix=$(PRE0))

build/1/check/Makefile:
	PKG_CONFIG="" \
	$(call _conf1,$(@D),--prefix=$(PRE0))

$(PRE0)/$(TGT)/bin/gcc: stage/0/gcc

$(ALLSTAGE): stage/% : build/done/%/stamp-done
