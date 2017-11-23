TERMUX_PKG_HOMEPAGE=https://nim-lang.org/
TERMUX_PKG_DESCRIPTION="Nim is a systems and applications programming language. Statically typed and compiled, it provides unparalleled performance in an elegant package."
TERMUX_PKG_VERSION=0.17.2
TERMUX_PKG_SRCURL=https://nim-lang.org/download/nim-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=aaff1b5023fc4a5708f1d7d9fd8e2a29f1a7f58bf496532ff1e9d7e7c7ec82bd
TERMUX_PKG_HOSTBUILD=yes
TERMUX_PKG_BUILD_IN_SRC=yes
#TERMUX_PKG_BLACKLISTED_ARCHES="x86_64"
TERMUX_PKG_DEPENDS="git, clang, libandroid-glob"
termux_step_host_build() {
	PATH=$TERMUX_STANDALONE_TOOLCHAIN/bin:$PATH
	cp ../src/* -r ./
	patch -p1 < $TERMUX_PKG_BUILDER_DIR/posix.nim.patch
	patch -p1 < $TERMUX_PKG_BUILDER_DIR/installer.ini.patch
	make -j $TERMUX_MAKE_PROCESSES
	make install
}
termux_step_make() {
	 sed -i "s%\@CC\@%${CC}%g"  config/nim.cfg
	 sed -i "s%\@CFLAGS\@%${CFLAGS}%g" config/nim.cfg
	 sed -i "s%\@LDFLAGS\@%${LDFLAGS}%g" config/nim.cfg
	 sed -i "s%\@CPPFLAGS\@%${CPPFLAGS}%g" config/nim.cfg
	 if [ $TERMUX_ARCH = "x86_64" ]; then
	export	NIM_ARCH=amd64
	elif [ $TERMUX_ARCH = "i686" ]; then
	export	NIM_ARCH=i386
	elif [ $TERMUX_ARCH = "aarch64" ]; then
	export	NIM_ARCH=arm64
	else 
	export NIM_ARCH=arm
	fi
	find -name   "stdlib_osproc.c" | xargs -n 1 sed -i 's',"/bin/sh\"\,\ 7","/data/data/com.termux/files/usr/bin/sh\"\,\ 40",'g'

	PATH=$TERMUX_PKG_HOSTBUILD_DIR/bin:$PATH

	if [ $NIM_ARCH = "amd64" ]; then
		sed -i 's/arm64/amd64/g' makefile
	fi
	make uos=linux mycpu=$NIM_ARCH uosname=android  -j $TERMUX_MAKE_PROCESSES LINKER=$CC useShPath=$TERMUX_PREFIX/bin/sh  # CC=$CC
	cp config/nim.cfg ../host-build/config
	
	nim --opt:size --define:termux -d:release --os:android --cpu:$NIM_ARCH  -t:-I/data/data/com.termux/files/usr/include -l:"-L/data/data/com.termux/files/usr/lib -landroid-glob" c koch.nim
	cd dist/nimble/src
	nim --define:termux -d:release --os:android --cpu:$NIM_ARCH  -t:-I/data/data/com.termux/files/usr/include -l:"-L/data/data/com.termux/files/usr/lib -landroid-glob" c nimble.nim
	echo 'tcc.options.linker = "-L${TERMUX_PREFIX}/lib -landroid-glob"' >> $TERMUX_PREFIX/lib/nim/config/nim.cfg
	cp nimble $TERMUX_PKG_SRCDIR/bin
}
termux_step_make_install() {
	./install.sh $TERMUX_PREFIX/lib
	cp koch $TERMUX_PREFIX/lib/nim/bin
	cp bin/nimble $TERMUX_PREFIX/lib/nim/bin 
	ln -sf $TERMUX_PREFIX/lib/nim/bin/nim $TERMUX_PREFIX/bin
	ln -sf $TERMUX_PREFIX/lib/nim/bin/koch $TERMUX_PREFIX/bin
	ln -sf $TERMUX_PREFIX/lib/nim/bin/nimble $TERMUX_PREFIX/bin
}
