#!/usr/bin/env bash

set -eu

if [[ ! -f "${PWD}/Cartfile" ]]; then
  echo "ERROR: appservices_local_dev.sh should be run from the root directory of the repository."
  exit 1
fi

if [[ "${#}" -lt 1 ]]
then
    echo "Usage:"
    echo "> To use the local application-services repository"
    echo "./appservices_local_dev.sh enable /path/to/application-services"
    echo "> To restore application-services to its Carthage version"
    echo "./appservices_local_dev.sh disable"
    exit 1
fi

msg () {
  printf "\033[0;34m> %s\033[0m\n" "${1}"
}

ACTION="${1}"

FRAMEWORK_LOCATION="${PWD}/Carthage/Build/iOS/MozillaAppServices.framework"

if [[ "${ACTION}" == "enable" ]]; then
  APP_SERVICES_DIR="${2-}"
  if [[ -z "${APP_SERVICES_DIR}" ]]; then
    echo "Please specify the application services directory to use!"
    exit 1
  fi
  msg "Using local Application Services (${APP_SERVICES_DIR})"
  if [ ! -h "${FRAMEWORK_LOCATION}" ]; then
    msg "Replacing Carthage package by symbolic link..."
    rm -rf "${FRAMEWORK_LOCATION}"
    ln -s "${APP_SERVICES_DIR}/Carthage/Build/iOS/Static/MozillaAppServices.framework" "${PWD}/Carthage/Build/iOS"
  fi
  msg "Building Application Services."
  pushd "${APP_SERVICES_DIR}"
  ./build-carthage.sh --no-archive
  popd
  echo ""
  msg "Done! You are now using application-services from ${APP_SERVICES_DIR}"
  msg "Note that any changes to application-services won't be reflected until you re-build the framework!"
  msg "To do so you can re-run this script with the same arguments."
elif [[ "${ACTION}" == "disable" ]]; then
  if [ -h "${FRAMEWORK_LOCATION}" ]; then
    msg "Removing symbolic link."
    rm -rf "${FRAMEWORK_LOCATION}"
    msg "Re-running the bootstrap script."
    carthage bootstrap --platform iOS application-services
    msg "Application Services is back on its Carthage version!"
  fi
else
  echo "Un-recognized action."
  exit 1
fi
