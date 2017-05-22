TERMUX_PKG_HOMEPAGE=https://www.mirbsd.org/mksh.htm
TERMUX_PKG_DESCRIPTION="the MirBSD™ Korn Shell"
TERMUX_PKG_VERSION=55
TERMUX_PKG_SRCURL=https://www.mirbsd.org/MirOS/dist/mir/mksh/mksh-R55.tgz
TERMUX_PKG_SHA256=ced42cb4a181d97d52d98009eed753bd553f7c34e6991d404f9a8dcb45c35a57
TERMUX_PKG_BUILD_IN_SRC=yes
TERMUX_PKG_FOLDERNAME=mksh
termux_step_make() {
chmod +x Build.sh
./Build.sh
}
termux_step_make_install() {
cp mksh $TERMUX_PREFIX/bin/mksh
cp mksh.1 $TERMUX_PREFIX/share/man/man1/mksh.1
cp lksh.1 $TERMUX_PREFIX/share/man/man1/lksh.1
mkdir -p $TERMUX_PREFIX/share/doc/mksh/examples/
cp dot.mkshrc $TERMUX_PREFIX/share/doc/mksh/examples/dot.mkshrc
}

