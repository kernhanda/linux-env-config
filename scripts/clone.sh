#!/usr/bin/env bash

# This is the one-liner installation script for these dotfiles. To install,
# curl https://raw.githubusercontent.com/kernhanda/linux-env-config/master/scripts/clone.sh | sh

main() {
  readonly configDir="${HOME}/.linux-env-config"
  readonly repo="https://github.com/kernhanda/linux-env-config"

  if [[ ! "$(command -v git)" ]]; then
    echo "This bootstrap script requires git. Aborting."
    exit 1
  fi

  if [[ -d "$configDir" ]]; then
    echo "The config directory (${configDir}) already exists. We will assume you already cloned the correct repository."
  else
    git clone --quiet --filter=blob:none "${repo}" "${configDir}"
  fi

  cd "${configDir}" || exit
  . setup.sh
}

main "$@"
