# Maintainer: the_swest
pkgname=dualcpy
pkgver=1.0.0
pkgrel=1
pkgdesc="Dual-screen scrcpy docking and control UI for Linux"
arch=('x86_64')
url="https://github.com/the_swest/DualCPY-Linux"
license=('GPL3')
depends=('android-tools' 'scrcpy' 'libx11' 'libxext')
makedepends=('python' 'python-pip' 'python-virtualenv')
source=("$pkgname-$pkgver.tar.gz::https://github.com/corigne/DualCPY-Linux/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
    cd "$srcdir/DualCPY-Linux-$pkgver"
    python -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install pyinstaller platformdirs
    make build PYTHON="venv/bin/python"
}

package() {
    cd "$srcdir/DualCPY-Linux-$pkgver"
    make install DESTDIR="$pkgdir" PREFIX=/usr
}
