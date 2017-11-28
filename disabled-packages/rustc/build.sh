TERMUX_PKG_HOMEPAGE=https://www.rust-lang.org
TERMUX_PKG_DEPENDS="clang"
TERMUX_PKG_VERSION=1.22.1
TERMUX_PKG_SHA256=80ee9ecc1e03ee63ea13c2612b61fc04fce9240476836f70c553ebaebd58fed6
TERMUX_PKG_SRCURL=https://static.rust-lang.org/dist/rustc-$TERMUX_PKG_VERSION-src.tar.xz
TERMUX_PKG_DESCRIPTION="A safe, concurrent, practical language."
TERMUX_PKG_MAINTAINER="@its-pointless"
TERMUX_PKG_KEEP_SHARE_DOC=true
# --disable-jemalloc --enable-clang --enable-llvm-link-shared --disable-option-checking
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-option-checking
--enable-clang
--disable-optimize-tests
--disable-debuginfo-tests
--disable-codegen-tests
--enable-local-rust
--enable-local-rebuild
"
#TERMUX_PKG_CLANG=no
termux_step_pre_configure () {
	termux_setup_cmake
	termux_setup_rust
	rustup target add $RUST_TARGET_TRIPLE
	RUST_BACKTRACE=1
	GCCT=$(which $CC)
	GCCP=$(which $CXX)
	mkdir -p $TERMUX_PKG_TMPDIR/lib

	mkdir -p $TERMUX_PKG_TMPDIR/bin
	cp $TERMUX_PREFIX/lib/libc++_shared.so $TERMUX_PKG_TMPDIR/lib
	# most configuration is done with this file
	export RUST_BACKTRACE=1	
	export PATH=$TERMUX_PKG_TMPDIR/bin:$PATH
	echo "$GCCT -L$TERMUX_PKG_TMPDIR/lib \$@" > $TERMUX_PKG_TMPDIR/bin/$CC
	echo "$GCCP -L$TERMUX_PKG_TMPDIR/lib \$@" > $TERMUX_PKG_TMPDIR/bin/$CXX
	chmod +x $TERMUX_PKG_TMPDIR/bin/$CC
	chmod +x $TERMUX_PKG_TMPDIR/bin/$CXX
	if [ $TERMUX_ARCH = "arm" ]; then          
		export LDFLAGS_armv7_linux_androideabi="$LDFLAGS"
		export CFLAGS_armv7_linux_androideabi="$CFLAGS"
		export CXXFLAGS_armv7_linux_androideabi="$CXXFLAGS"
		export LD_armv7_linux_androideabi="$LD"
	else
		export LDFLAGS_${TERMUX_ARCH}_linux_android="-L$TERMUX_PKG_BUILDDIR/build/$RUST_TARGET_TRIPLE/llvm/lib -lLLVMCo"
		export CFLAGS_${TERMUX_ARCH}_linux_android="$CFLAGS $CPPFLAGS $LDFLAGS"
		export CFLAGS_${TERMUX_ARCH}_linux_android="$CFLAGS" # -L$TERMUX_PKG_BUILDDIR/build/$RUST_TARGET_TRIPLE/llvm/lib -lLLVMCore"
		export LD_${TERMUX_ARCH}_linux_android="$LD"
		export CXXFLAGS_${TERMUX_ARCH}_linux_android="$CXXFLAGS" #	-L$TERMUX_PKG_BUILDDIR/build/$RUST_TARGET_TRIPLE/llvm/lib -lLLMCore"
	fi
	# x86_64 fails to build full documentation due to build system libs being linked. 
	if [ $TERMUX_ARCH = "x86_64" ]; then
		sed $TERMUX_PKG_BUILDER_DIR/config.tomlx86_64 \
			-e "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
			-e "s|@TERMUX_HOST_PLATFORM@|$TERMUX_HOST_PLATFORM|g" \
			-e "s|@RUST_TARGET_TRIPLE@|$RUST_TARGET_TRIPLE|g" \
			-e "s|@RUSTC@|$(which rustc)|g" \
			-e "s|@CARGO@|$(which cargo)|g" > $TERMUX_PKG_BUILDDIR/config.toml
	else
		sed $TERMUX_PKG_BUILDER_DIR/config.toml \
                        -e "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
                        -e "s|@TERMUX_HOST_PLATFORM@|$TERMUX_HOST_PLATFORM|g" \
                        -e "s|@RUST_TARGET_TRIPLE@|$RUST_TARGET_TRIPLE|g" \
			-e "s|@RUSTC@|$(which rustc)|g" \
			-e "s|@CARGO@|$(which cargo)|g" > $TERMUX_PKG_BUILDDIR/config.toml
	fi
	cp $TERMUX_PKG_BUILDDIR/config.toml $TERMUX_PKG_TMPDIR
	_CC=$CC	
	unset CFLAGS CXXFLAGS LDFLAGS CC CXX LD CPP CPPFLAGS PREFIX
	export _arch_args="--host=$RUST_TARGET_TRIPLE --target=$RUST_TARGET_TRIPLE"
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" $_arch_args --local-rust-root=$RUSTUP_HOME"
}

termux_step_make () {
	mv config.toml config.oldtok
	cp $TERMUX_PKG_TMPDIR/config.toml config.toml
../src/x.py build ../src/src/llvm --host $RUST_TARGET_TRIPLE --target $RUST_TARGET_TRIPLE 
#if [ $TERMUX_ARCH = "i686" ] || [ $TERMUX_ARCH = "x86_64" ]; then
#echo "$GCCT $TERMUX_PKG_BUILDDIR/build/$RUST_TARGET_TRIPLE/llvm/lib -lLLVMCore-L$TERMUX_PKG_TMPDIR/lib \$@" > $TERMUX_PKG_TMPDIR/bin/$_CC
#fi
export LD_LIBRARY_PATH="/home/builder/.termux-build/rustc/build/build/x86_64-unknown-linux-gnu/stage2/lib"
	make
	make dist # CFG_TARGET=$RUST_TARGET_TRIPLE  CFG_HOST=$RUST_TARGET_TRIPLE
}

termux_step_make_install () {
	$TERMUX_PKG_SRCDIR/x.py dist $_arch_args
	mkdir -p $TERMUX_PKG_BUILDDIR/install
	if [ $TERMUX_ARCH = "x86_64" ]; then
		for tar in rustc rust-std; do
                	tar -xf $TERMUX_PKG_BUILDDIR/build/dist/$tar-$TERMUX_PKG_VERSION-$RUST_TARGET_TRIPLE.tar.gz -C $TERMUX_PKG_BUILDDIR/install
                	# uninstall previous version
                	$TERMUX_PKG_BUILDDIR/install/$tar-$TERMUX_PKG_VERSION-$RUST_TARGET_TRIPLE/install.sh --uninstall --prefix=$TERMUX_PREFIX || true
                	$TERMUX_PKG_BUILDDIR/install/$tar-$TERMUX_PKG_VERSION-$RUST_TARGET_TRIPLE/install.sh --prefix=$TERMUX_PREFIX
		done
	else
	for tar in rustc rust-docs rust-std; do
		tar -xf $TERMUX_PKG_BUILDDIR/build/dist/$tar-$TERMUX_PKG_VERSION-$RUST_TARGET_TRIPLE.tar.gz -C $TERMUX_PKG_BUILDDIR/install
		# uninstall previous version
		$TERMUX_PKG_BUILDDIR/install/$tar-$TERMUX_PKG_VERSION-$RUST_TARGET_TRIPLE/install.sh --uninstall --prefix=$TERMUX_PREFIX || true
		$TERMUX_PKG_BUILDDIR/install/$tar-$TERMUX_PKG_VERSION-$RUST_TARGET_TRIPLE/install.sh --prefix=$TERMUX_PREFIX
	done
	fi
	cd "$TERMUX_PREFIX/lib"
	ln -sf rustlib/$RUST_TARGET_TRIPLE/lib/*.so .
}

termux_step_post_massage () {
	rm $TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX/lib/rustlib/{components,rust-installer-version,install.log,uninstall.sh}
}
