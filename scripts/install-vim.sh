#!/bin/bash

set -ev

case "${TRAVIS_OS_NAME}" in
  linux)
    git clone --depth 1 --branch "${VIM_VERSION}" https://github.com/vim/vim /tmp/vim
    cd /tmp/vim
    ./configure --prefix="${HOME}/vim" \
      --with-features=huge \
      --enable-fail-if-missing
    make -j2
    make install
    ;;
  osx)
    brew update
    brew upgrade
    brew install vim
    ;;
  *)
    echo "Unknown value of \${TRAVIS_OS_NAME}: ${TRAVIS_OS_NAME}"
    exit 65
    ;;
esac
