#!/usr/bin/env bash

set -euo pipefail

DIR="$(cd "$(dirname "${0}")/.." && pwd)"
cd "${DIR}"

mkdir -p "${DIR}/tmp/test/bin"
trap 'rm -rf "${DIR}/tmp/test"' EXIT

PATH="${DIR}/tmp/test/bin:$PATH"

cp test/buf.bash tmp/test/bin/buf
chmod +x tmp/test/bin/buf

# prevent the GITHUB_SHA set by actions from being used in test
unset GITHUB_SHA

export BSR_COMMIT="feedfacecafefeedfacecafefeedface"

test_push() {
  export GITHUB_SHA BUF_TOKEN WANT_BUF_TOKEN WANT_ARGS OLD_BUF_VERSION
  set +e
  ./push.bash "$@" > tmp/test/stdout 2> tmp/test/stderr
  GOT_EXIT_CODE="${?}"
  set -e
  if [ "${WANT_STDERR}" != "$(cat tmp/test/stderr)" ]; then
    echo "UNEXPECTED STDERR:" >&2
    diff -u <(echo "${WANT_STDERR}") <(cat tmp/test/stderr) >&2
    exit 1
  fi
  if [ "${WANT_STDOUT}" != "$(cat tmp/test/stdout)" ]; then
    echo "UNEXPECTED STDOUT:" >&2
    diff -u <(echo "${WANT_STDOUT}") <(cat tmp/test/stdout) >&2
    exit 1
  fi
  if [ -n "${WANT_EXIT_CODE}" ]; then
    if [ "${WANT_EXIT_CODE}" != "${GOT_EXIT_CODE}" ]; then
      echo "Expected exit code ${WANT_EXIT_CODE}, got ${GOT_EXIT_CODE}"
      exit 1
    fi
  fi
  rm -f tmp/test/stdout tmp/test/stderr
  unset GITHUB_SHA BUF_TOKEN WANT_BUF_TOKEN WANT_ARGS OLD_BUF_VERSION
}

echo "testing happy path"
GITHUB_SHA=fake-sha
BUF_TOKEN=fake-token
WANT_BUF_TOKEN=fake-token
WANT_ARGS="push --tag fake-sha some/input/path"
WANT_STDOUT="::add-mask::fake-token
${BSR_COMMIT}"
WANT_STDERR=""
WANT_EXIT_CODE=0
test_push some/input/path main
echo "ok"

echo "testing non-main track"
GITHUB_SHA=fake-sha
BUF_TOKEN=fake-token
WANT_BUF_TOKEN=fake-token
WANT_ARGS="push --tag fake-sha --track non-main some/input/path"
WANT_STDOUT="::add-mask::fake-token
${BSR_COMMIT}"
WANT_STDERR=""
WANT_EXIT_CODE=0
test_push some/input/path non-main
echo "ok"

echo "testing non-main track with old buf version"
OLD_BUF_VERSION=1
GITHUB_SHA=fake-sha
BUF_TOKEN=fake-token
WANT_BUF_TOKEN=fake-token
WANT_ARGS="push --tag fake-sha --track non-main some/input/path"
WANT_STDOUT="::add-mask::fake-token
::error::The installed version of buf does not support setting the track. Please use buf v1.0.0-rc11 or newer."
WANT_STDERR=""
WANT_EXIT_CODE=1
test_push some/input/path non-main
echo "ok"

echo "testing no input"
GITHUB_SHA=fake-sha
BUF_TOKEN=fake-token
WANT_STDOUT=""
WANT_STDERR="Usage: ./push.bash <input> <track>"
WANT_EXIT_CODE=1
test_push
echo "ok"

echo "testing no GITHUB_SHA"
BUF_TOKEN=fake-token
WANT_STDOUT='::add-mask::fake-token
::error::the commit was not provided'
WANT_STDERR=""
WANT_EXIT_CODE=1
test_push some/input/ main
echo "ok"

echo "testing no BUF_TOKEN"
GITHUB_SHA=fake-sha
WANT_STDOUT='::add-mask::
::error::a buf authentication token was not provided'
WANT_STDERR=""
WANT_EXIT_CODE=1
test_push some/input/path main
echo "ok"
