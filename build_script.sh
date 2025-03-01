#!/bin/bash
set -e

# 定义库版本
OPENSSL_VER="1.1.1w"
EXPAT_VER="2.5.0"
ZLIB_VER="1.3.1"
CARES_VER="1.21.0"
LIBSSH2_VER="1.11.0"

# 下载并编译 OpenSSL
curl -LO "https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz"
tar xf openssl-${OPENSSL_VER}.tar.gz
cd openssl-${OPENSSL_VER}
./Configure no-shared --prefix=$PREFIX android-arm64
make -j$(nproc)
make install_sw
cd ..

# 下载并编译其他依赖库
compile_lib() {
  local name=$1 url=$2
  curl -LO "$url"
  tar xf "${name}.tar.*"
  cd "${name}"
  ./configure --host=$HOST --prefix=$PREFIX --disable-shared
  make -j$(nproc) install
  cd ..
}

compile_lib "expat-${EXPAT_VER}" "https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-${EXPAT_VER}.tar.bz2"
compile_lib "zlib-${ZLIB_VER}" "https://github.com/madler/zlib/releases/download/v${ZLIB_VER}/zlib-${ZLIB_VER}.tar.gz"
compile_lib "c-ares-${CARES_VER}" "https://github.com/c-ares/c-ares/releases/download/cares-1_21_0/c-ares-${CARES_VER}.tar.gz"
compile_lib "libssh2-${LIBSSH2_VER}" "https://libssh2.org/download/libssh2-${LIBSSH2_VER}.tar.bz2"

# 编译 aria2
git clone --depth 1 https://github.com/aria2/aria2
cd aria2
autoreconf -i
./configure \
  --host=$HOST \
  --disable-nls \
  --with-openssl \
  --with-libexpat \
  --with-libcares \
  --with-libz \
  --with-libssh2 \
  CXXFLAGS="-Os -g" \
  CFLAGS="-Os -g" \
  LDFLAGS="-static-libstdc++"
make -j$(nproc)
$STRIP src/aria2c
