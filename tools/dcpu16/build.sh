#!/bin/sh

# This script checks out the latest sources, builds them
# and makes a tarball.

set -e

ROOT=`mktemp -d`

cd "${ROOT}"
mkdir src
mkdir install
mkdir out

cd src

echo "Checking out LLVM..."
git clone git://github.com/krasin/llvm-dcpu16.git
cd llvm-dcpu16/tools

TOOLCHAIN_NAME="llvm-dcpu16"
mkdir "${ROOT}/install/${TOOLCHAIN_NAME}"

echo "Checking out Clang..."
git clone git://github.com/krasin/clang-dcpu16.git clang # Checkout Clang
mkdir ../cbuild
cd ../cbuild
cmake -DCMAKE_INSTALL_PREFIX="${ROOT}/install/${TOOLCHAIN_NAME}" ..

echo "Building..."
make -j4

echo "Installing..."
make install -j4

echo "Making a tarball"
cd "${ROOT}/install"
TARBALL_PATH="${ROOT}/out/${TOOLCHAIN_NAME}.tar.gz"
tar -czf "${TARBALL_PATH}" "${TOOLCHAIN_NAME}"

echo "Done. Tarball is ${TARBALL_PATH}"


