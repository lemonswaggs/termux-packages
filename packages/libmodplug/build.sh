TERMUX_PKG_HOMEPAGE="https://github.com/Konstanty/libmodplug"
TERMUX_PKG_DESCRIPTION="the library which was part of the Modplug-xmms project"
local _COMMIT=5a39f5913d07ba3e61d8d5afdba00b70165da81d
TERMUX_PKG_VERSION=0.8.9.0
TERMUX_PKG_SRCURL=https://github.com/Konstanty/libmodplug/archive/$_COMMIT.zip
TERMUX_PKG_FOLDERNAME="libmodplug-$_COMMIT"
TERMUX_PKG_SHA256=12d12362428ebcefd473e56ff94faa6ee5c066b777e153d2bbca15c1e379d1bc
termux_step_post_make_install() {
# it only installs the static lib with cmake so we have to make a shared lib...
rm -f $TERMUX_PREFIX/lib/libmodplug.so
$CC --shared -Wl,--whole-archive -l:$TERMUX_PREFIX/lib/libmodplug.a -Wl,--no-whole-archive $LDFLAGS -lgnustl_shared -o $TERMUX_PREFIX/lib/libmodplug.so
}
