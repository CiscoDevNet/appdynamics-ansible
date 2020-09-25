#!/usr/bin/env sh

# Copyright (c) AppDynamics, Inc., and its affiliates 2020
# All Rights Reserved.
# THIS IS UNPUBLISHED PROPRIETARY CODE OF APPDYNAMICS, INC.
#
# The copyright notice above does not evidence any actual or
# intended publication of such source code

set -o nounset

readonly OS="$(uname -s)"
readonly ARCH="$(uname -m)"

readonly ME="$(basename "$0")"
readonly HERE=$(CDPATH='' cd "$(dirname "$0")" && pwd -P)

readonly DOWNLOAD_PATH="download-file"
readonly DEFAULT_DOWNLOAD_SITE="https://download-files.appdynamics.com"

#ansible agents
readonly DOTNET_AGENT_ARCHIVE_NAME="dotNetAgentSetup64"
readonly DOTNET_AGENT_DOWNLOAD_PATH="dotnet"

# DotNetcore link seem to require authentication atm.
# test https://download.appdynamics.com/download/prox/download-file/dotnet-core/20.7.0/AppDynamics-DotNetCore-linux-x64-20.7.0.zip
#readonly DOTNET_CORE_AGENT_ARCHIVE_NAME="AppDynamics-DotNetCore-linux-x64"
#readonly DOTNET_CORE_AGENT_DOWNLOAD_PATH="dotnet-core"

readonly JAVA_AGENT_ARCHIVE_NAME="AppServerAgent"
readonly JAVA_AGENT_DOWNLOAD_PATH="sun-jvm"

readonly IBM_JAVA_AGENT_ARCHIVE_NAME="AppServerAgent-ibm"
readonly IBM_JAVA_AGENT_DOWNLOAD_PATH="ibm-jvm"

readonly MACHINE_AGENT_ARCHIVE_NAME="machineagent-bundle-64bit-linux"
readonly MACHINE_AGENT_DOWNLOAD_PATH="machine-bundle"

#ansible: MA for windows
readonly MACHINE_AGENT_ARCHIVE_NAME_WIN="machineagent-bundle-64bit-windows"

readonly ZERO_AGENT_ARCHIVE_NAME="appdynamics-zero-agent"
readonly ZERO_AGENT_DOWNLOAD_PATH="zero-agent"

readonly ARCHIVE_TYPE="zip"

#ansible
readonly WIN_ARCHIVE_TYPE="msi"

readonly HTTP_STATUS_FILE="http_$$.status"

readonly ERR_HELP=1
readonly ERR_BAD_ARGS=2
readonly ERR_DEPS=3
readonly ERR_BAD_RESPONSE=4
readonly ERR_NETWORK=5
readonly ERR_INTEGRITY=6
readonly ERR_MISSING_ARCHIVE=7
readonly ERR_MISSING_LIB_DEPS=8
readonly ERR_UNSUPPORTED_PLATFORM=9

if [ "${OS}" = "Darwin" ]; then
  readonly MD5="md5 -q"
else
  readonly MD5="md5sum"
fi

# Switch to the script's directory.
cd "${HERE}" || exit

###################################################################################################################
#                                   USAGE AND ERROR HANDLING FUNCTIONS                                            #
###################################################################################################################

# Bare command usage function.
_usage() {
  echo "Usage: $ME [OPTIONS...]"
  echo "  -h, --help, help                     Print this help"
  echo
  echo "  download AGENT                       Agent to download (choices: sun-java, ibm-java, machine, zero)"
  echo "    -v, --version VERSION              Version number for the supplied agent"
  echo "    -c, --checksum CHECKSUM            MD5 checksum of the the supplied agent"
  echo
  echo "  install ARGS                         Install Zero Agent with the supplied arguments"
}

# Prints an error message with an 'ERROR' prefix to stderr.
#
# Args:
#   $1 - error message.
error_msg() {
  echo "ERROR: $1" >&2
}

# Prints an informational message to stdout.
#
# Args:
#   $1 - message
info_msg() {
  echo "INFO: $1"
}

# Prints the command usage followed by an exit.
#
# Args:
#   $1 (optional) - exit code to use.
exit_with_usage() {
  _usage >&2
  if [ $# -gt 0 ]; then
    exit "$1"
  else
    exit "${ERR_HELP}"
  fi
}

# Prints an error message followed by an exit.
#
# Args:
#   $1 - error message.
#   $2 - exit code to use.
exit_with_error() {
  error_msg "$1"
  exit "$2"
}

# Prints an error message follwed by an usage and exit with `ERR_BAD_ARGS`.
#
# Args:
#   $1 - error message.
exit_bad_args() {
  error_msg "$1"
  exit_with_usage ${ERR_BAD_ARGS}
}

# Removes temporary file during exit or interrupt.
cleanup() {
  rm -f "${HTTP_STATUS_FILE}"
  rm -f ${DOWNLOAD_PAGE_OUTPUT}

}
trap cleanup EXIT TERM INT

###################################################################################################################
#                                              HELPER FUNCTIONS                                                   #
###################################################################################################################

# Checks if the platform operating system and machine hardware are
# compatible with the zero agent. Incompatibility results in exiting
# with `ERR_UNSUPPORTED_PLATFORM`.
check_platform_compatibility() {
  if [ "${OS}" != "Linux" ] || [ "${ARCH}" != "x86_64" ]; then
    exit_with_error "Unsupported operating system or machine architecture: ${OS} ${ARCH}. \
      Cannot install" ${ERR_UNSUPPORTED_PLATFORM}
  fi
}

# Checks dependencies required by this script. Unmet dependencies result
# in exit with `ERR_DEPS`.
check_dependencies() {
  if ! command -v curl >/dev/null 2>&1; then
    exit_with_error "curl command unavailable" ${ERR_DEPS}
  elif ! command -v ${MD5} >/dev/null 2>&1; then
    exit_with_error "${MD5} command unavailable" ${ERR_DEPS}
  elif ! command -v "awk" >/dev/null 2>&1; then
    exit_with_error "awk command unavailable" ${ERR_DEPS}
  fi
}

# Returns the download URL for the provided agent and version. Incorrect
# argument results in exit with `ERR_BAD_ARGS`.
#
# Args:
#   $1 - agent type (java|machine|zero)
#   $2 - base url
#   $3 - agent version
# Returns:
#   the downlod URL for the specified agent and version.
get_download_url() {
  if [ "$1" = "sun-java" ]; then
    echo "$2/${JAVA_AGENT_DOWNLOAD_PATH}/$3/${JAVA_AGENT_ARCHIVE_NAME}-$3.${ARCHIVE_TYPE}"
  elif [ "$1" = "ibm-java" ]; then
    echo "$2/${IBM_JAVA_AGENT_DOWNLOAD_PATH}/$3/${IBM_JAVA_AGENT_ARCHIVE_NAME}-$3.${ARCHIVE_TYPE}"
  elif [ "$1" = "machine" ]; then
    echo "$2/${MACHINE_AGENT_DOWNLOAD_PATH}/$3/${MACHINE_AGENT_ARCHIVE_NAME}-$3.${ARCHIVE_TYPE}"
  elif [ "$1" = "zero" ]; then
    echo "$2/${ZERO_AGENT_DOWNLOAD_PATH}/$3/${ZERO_AGENT_ARCHIVE_NAME}-$3.${ARCHIVE_TYPE}"
    #ansible additions
  elif [ "$1" = "dotnet" ]; then
    echo "$2/${DOTNET_AGENT_DOWNLOAD_PATH}/$3/${DOTNET_AGENT_ARCHIVE_NAME}-$3.${WIN_ARCHIVE_TYPE}"
  #dotnet-core seem to require authentication
  #elif [ "$1" = "dotnet-core" ]; then
  #  echo "$2/${DOTNET_CORE_AGENT_DOWNLOAD_PATH}/$3/${DOTNET_CORE_AGENT_ARCHIVE_NAME}-$3.${ARCHIVE_TYPE}"
  elif [ "$1" = "machine-win" ]; then
    echo "$2/${DOTNET_CORE_AGENT_DOWNLOAD_PATH}/$3/${MACHINE_AGENT_ARCHIVE_NAME_WIN}-$3.${ARCHIVE_TYPE}"
  else
    exit_bad_args "unknown agent type: $1"
  fi
}

# Runs `curl` command to download the agent archive. Network or HTTP failure
# results in exit with `ERR_NETWORK` and `ERR_BAD_RESPONSE` respectively.
#
# Args:
#   $1 - archive download URL.
do_curl() {
  if ! curl -qLO --write-out '\n%{http_code}\n' "$1" >"${HTTP_STATUS_FILE}"; then
    exit_with_error "failed to download specified agent" "${ERR_NETWORK}"
  fi

  readonly http_code=$(tail -n 1 "${HTTP_STATUS_FILE}")
  if [ "${http_code}" -ge 400 ] && [ "${http_code}" -lt 600 ]; then
    exit_with_error "bad HTTP response code: ${http_code}" "${ERR_BAD_RESPONSE}"
  fi
}

simulate_curl() {
  if ! curl -qL --write-out '\n%{http_code}\n' "$1" >"${HTTP_STATUS_FILE}"; then
    exit_with_error "failed to download specified agent" "${ERR_NETWORK}"
  fi

  readonly http_code=$(tail -n 1 "${HTTP_STATUS_FILE}")
  if [ "${http_code}" -ge 400 ] && [ "${http_code}" -lt 600 ]; then
    exit_with_error "bad HTTP response code: ${http_code}" "${ERR_BAD_RESPONSE}"
  fi
}

# Verifies that the agent archive file is actually downloaded AND the on-disk
# checksum matches the one provided on the command-line. The function exits
# with `ERR_MISSING_ARCHIVE` if the specified archive file is missing and
# exits with `ERR_INTEGRITY` if the checksums do not match.
#
# Args:
#   $1 - name of the downloaded archive file
#   $2 - the provided checksum
verify() {
  readonly archive="$1"
  readonly cksum="$2"

  # Check if we actually have a file.
  if [ ! -f "${archive_name}" ]; then
    exit_with_error "missing archive: ${archive}" "${ERR_MISSING_ARCHIVE}"
  fi
  info_msg "Successfully downloaded ${archive}"

  # Validate file integrity.
  readonly true_cksum=$(${MD5} "${archive}" | awk '{print $1}')
  if [ "${true_cksum}" != "${cksum}" ]; then
    exit_with_error "integrity check failed: expected=${cksum}, got=${true_cksum}" $ERR_INTEGRITY
  fi
  info_msg "Integrity check passed!"
}

# Extract the spicified agent into specified directory
# Args:
#   $1 - name prefix of the specified agent.
#   $2 - directory name. Default current directory.
#   $3 - exit if file does not exists. Default : true
do_unzip() {
  archive_prefix=$1
  agent_directory_name=${2:-}
  fail_if_not_exists=${3:-true}
  agent_artifact=$(ls | grep -E "$1-[-0-9.]+\.zip") 2>/dev/null
  if [ -f "${agent_artifact}" ]; then
    if [ ! -d "${agent_directory_name}" ]; then
      info_msg "Extracting ${agent_artifact}..."
      if ! unzip -q -o -d "${agent_directory_name}" "${agent_artifact}"; then
        exit_with_error "Failed to extract ${agent_artifact}" ${ERR_INTEGRITY}
      fi
    fi
  elif ${fail_if_not_exists}; then
    exit_with_error "Failed to discover agent artifact with prefix ${archive_prefix}" ${ERR_MISSING_ARCHIVE}
  fi
}

# Tests that it is safe to enable LD_PRELOAD in this environment.  We'll do
# this by temporarily setting the LD_PRELOAD environmental variable, and then
# running a trivial command ("ls").
#
# Some Linux distros include a back-level C library, which will not allow the
# libpreload.so library to load.  We cannot install in this environment.
test_ldpreload() {
  SAVE_LDPRELOAD=${LD_PRELOAD:-}
  export LD_PRELOAD=${PWD}/zeroagent/lib64/libpreload.so
  ls >/dev/null
  rc=$?
  export LD_PRELOAD=${SAVE_LDPRELOAD}
  return ${rc}
}

###################################################################################################################
#                                             COMMAND FUNCTIONS                                                   #
###################################################################################################################

# Implements the `download` sub-command. This involves downloading the
# specified agent and verifying its integrity.
#
# Args: [sun-java|ibm-java|machine|machine-win|dotnet|zero] --version VERSION --checksum CHECKSUM
download() {
  while [ $# -gt 0 ]; do
    case "$1" in
    -v | --version)
      [ -n "${version:-}" ] && exit_bad_args "--version already specified"
      shift
      readonly version="${1:-}"
      ;;
    -c | --checksum)
      [ -n "${checksum:-}" ] && exit_bad_args "--checksum already specified"
      shift
      readonly checksum="${1:-}"
      ;;
    -u | --url)
      shift
      url="${1:-}"
      ;;
    sun-java | ibm-java | machine | machine-win | dotnet | zero)
      [ -n "${agent:-}" ] && exit_bad_args "multiple agents must be downloaded in separate command invocations"
      readonly agent="${1:-}"
      ;;
    *)
      exit_bad_args "unknown argument: $1"
      ;;
    esac
    shift
  done

  if [ -z "${agent:-}" ] || [ -z "${version:-}" ] || [ -z "${checksum:-}" ]; then
    exit_bad_args "missing one or more of agent type, version and checksum"
  fi

  # Get the download URL.
  url="${url:-${DEFAULT_DOWNLOAD_SITE}}"
  readonly download_url=$(get_download_url "${agent}" "${url}/${DOWNLOAD_PATH}" "${version}")

  #ansible ->>>>> stop here. Cos all we need is the url
  echo "$download_url"
  #exit 0

  # Get the archive name.
  readonly archive_name=$(basename "${download_url}")

  # Actual download: curl the URL.
  info_msg "Downloading ${agent} agent from ${download_url}"
  do_curl "${download_url}"

  #simulate_curl ${download_url}

  # Validate the downloaded file.
  # ansible - checksum verification not needed..
  #verify "${archive_name}" "${checksum}"
}

# Implements the `install` sub-command. This involves unzip the
# downloaded agent in current directory and install zeroagent.
#
# Args:  --account ACCOUNT --application APPLICATION --access-key ACCESS_KEY
#        --controller-url CONTROLLER_URL --zero-service-url ZERO_SERVICE_URL
install() {
  # Let's make sure our machine specs can run the agent
  check_platform_compatibility

  do_unzip "${JAVA_AGENT_ARCHIVE_NAME}" javaagent
  do_unzip "${IBM_JAVA_AGENT_ARCHIVE_NAME}" ibm-javaagent
  do_unzip "${MACHINE_AGENT_ARCHIVE_NAME}" machineagent false
  # Zero agent artifact contains zeroagent directory. Skip the directory name.
  do_unzip "${ZERO_AGENT_ARCHIVE_NAME}"

  # Actual install of zeroagent
  if test_ldpreload; then
    info_msg "Installing AppDynamics Zero Agent..."
    ./zeroagent/bin/zeroctl install "$@"
  else
    exit_with_error "Zero Agent library dependencies unmet.  Cannot install" ${ERR_MISSING_LIB_DEPS}
  fi
}

###################################################################################################################
#                                             MAIN ENTRYPOINT                                                     #
###################################################################################################################

main() {
  if [ $# -le 0 ]; then
    exit_with_usage
  fi

  # Let's ensure we have everything we need.
  check_dependencies

  while [ $# -gt 0 ]; do
    case "$1" in
    download)
      shift
      download "$@"
      exit $?
      ;;
    install)
      shift
      install "$@"
      exit $?
      ;;
    -h | --help | help)
      exit_with_usage
      ;;
    *)
      exit_bad_args "unknown command: $1"
      ;;
    esac
    shift
  done
}

main "$@"
