#!/usr/bin/env bash

# This file is copied from https://github.com/rust-embedded/cross/blob/master/docker/musl.sh
# which uses the MIT license, copied here
# (commit https://github.com/rust-embedded/cross/commit/7d09c5e5a2306ec3d01ea35bcdfa4747e27eef26)

# Copyright (c) 2016 Jorge Aparicio
#
# Permission is hereby granted, free of charge, to any
# person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the
# Software without restriction, including without
# limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following
# conditions:

# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions
# of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
# ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

set -x
set -euo pipefail

# shellcheck disable=SC1091

hide_output() {
    set +x
    trap "
        echo 'ERROR: An error was encountered with the build.'
        cat /tmp/build.log
        exit 1
    " ERR
    bash -c 'while true; do sleep 30; echo $(date) - building ...; done' &
    PING_LOOP_PID=$!
    "${@}" &> /tmp/build.log
    trap - ERR
    kill "${PING_LOOP_PID}"
    set -x
}

main() {
    local version=fd6be58

    local td
    td="$(mktemp -d)"

    pushd "${td}"
    curl --retry 3 -sSfL "https://github.com/richfelker/musl-cross-make/archive/${version}.tar.gz" -O
    tar --strip-components=1 -xzf "${version}.tar.gz"

    # Don't depend on the mirrors of sabotage linux that musl-cross-make uses.
    local linux_headers_site=https://ci-mirrors.rust-lang.org/rustc/sabotage-linux-tarballs
    local linux_ver=headers-4.19.88

    # alpine GCC is built with `--enable-default-pie`, so we want to
    # ensure we use that. we want support for shared runtimes except for
    # libstdc++, however, the only way to do that is to simply remove
    # the shared libraries later. on alpine, binaries use static-pie
    # linked, so our behavior has maximum portability, and is consistent
    # with popular musl distros.
    hide_output make install "-j$(nproc)" \
        GCC_VER=9.4.0 \
        MUSL_VER=1.2.5 \
        BINUTILS_VER=2.33.1 \
        DL_CMD='curl --retry 3 -sSfL -C - -o' \
        LINUX_HEADERS_SITE="${linux_headers_site}" \
        LINUX_VER="${linux_ver}" \
        OUTPUT=/usr/local/ \
        "GCC_CONFIG += --enable-default-pie --enable-languages=c,c++,fortran" \
        "${@}"

    popd

    rm -rf "${td}"
    rm "${0}"
}

main "${@}"

