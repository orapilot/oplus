#!/usr/bin/env bash
set -e

# Increase the pip timeout to handle TimeoutError
export PIP_DEFAULT_TIMEOUT=200

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
ROOT=$DIR/../
cd $ROOT

# updating uv on macOS results in 403 sometimes
function update_uv() {
  for i in $(seq 1 5);
  do
    if uv self update; then
      return 0
    else
      sleep 2
    fi
  done
  echo "Failed to update uv 5 times!"
}

if ! command -v "uv" > /dev/null 2>&1; then
  echo "installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  UV_BIN='$HOME/.cargo/env'
  ADD_PATH_CMD=". \"$UV_BIN\""
  eval $ADD_PATH_CMD
fi
#disable keyring
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring

echo "updating uv..."
update_uv


# otherwise it will install cpython-3.12.3-macos-aarch64-non
uv toolchain install

# TODO: remove --no-cache once this is fixed: https://github.com/astral-sh/uv/issues/4378
echo "installing python packages..."
uv venv
ln -s /usr/include/python3.12/ .venv/include
uvx pip --python .venv/bin/python3 install casadi==3.6.5 -v
uv --no-cache sync --all-extras
source .venv/bin/activate

echo "PYTHONPATH=${PWD}" > $ROOT/.env
if [[ "$(uname)" == 'Darwin' ]]; then
  echo "# msgq doesn't work on mac" >> $ROOT/.env
  echo "export ZMQ=1" >> $ROOT/.env
  echo "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES" >> $ROOT/.env
fi

