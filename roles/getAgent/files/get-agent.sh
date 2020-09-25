#!/usr/bin/env sh

set -o nounset

readonly OS="$(uname -s)"
readonly ARCH="$(uname -m)"
readonly ME="$(basename "$0")"
readonly HERE=$(CDPATH='' cd "$(dirname "$0")" && pwd -P)

readonly DEFAULT_DOWNLOAD_SITE="https://download-files.appdynamics.com"

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
readonly ERR_GENERIC=10

APPAGENT=""
PLATFORM=""
EUM=""
EVENTS=""
VERSION=""
DOWNLOAD_PAGE_OUTPUT="tmp.json"

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
  echo "  download AGENT                       Agent to download (choices: sun-java, ibm-java, machine, machine-win, dotnet)"
  echo "    -v, --version VERSION              Version number for the supplied agent"
  echo
  echo "  install ARGS                         Install Download Agent with the supplied arguments"
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
  elif ! command -v "jq" >/dev/null 2>&1; then
    exit_with_error "jq command unavailable" ${ERR_DEPS}
  elif ! command -v "awk" >/dev/null 2>&1; then
    exit_with_error "awk command unavailable" ${ERR_DEPS}
  fi
}

#Supported agent types:
#sun-java|ibm-java|machine|machine-win|dotnet|db|db-win
download_options() {
  if [ "$1" = "sun-java" -o "$1" = "java" ]; then
    APPAGENT="jvm%2Cjava-jdk8" #APPAGENT="jvm"
    matchString="sun-jvm"
    PLATFORM="linux"
  elif [ "$1" = "ibm-java" ]; then
    APPAGENT="jvm%2Cjava-jdk8"
    matchString="ibm-jvm"
    PLATFORM="linux"
  elif [ "$1" = "machine" ]; then
    APPAGENT="machine"
    PLATFORM="linux"
    matchString="machineagent-bundle-64bit-linux"
  elif [ "$1" = "machine-windows" -o "$1" = "machine-win" ]; then
    APPAGENT="machine"
    PLATFORM="windows"
    matchString="machineagent-bundle-64bit-windows"
  elif [ "$1" = "dotnet" ]; then
    APPAGENT="dotnet"
    matchString="dotnet"
    PLATFORM="windows"
  elif [ "$1" = "db" -o "$1" = "dbagent" ]; then
    APPAGENT="db"
    matchString="db-agent"
    PLATFORM="linux"
  elif [ "$1" = "db-win" -o "$1" = "db-windows" ]; then
    APPAGENT="db"
    matchString="db-agent-winx64"
    PLATFORM="windows"
  else
    exit_bad_args "unknown agent type: $1"
  fi
}

# Returns the download URL for the provided agent and version. Incorrect
# argument results in exit with `ERR_BAD_ARGS`.
#
# Args:
#   $1 - agent type (java|machine|)
#   $3 - agent version
# Returns:
#   the downlod URL for the specified agent and version.
get_download_url() {
  VERSION="$2"
  #portal_page="https://download.appdynamics.com/download/downloadfile/?version=${VERSION}&apm=${APPAGENT}&os=${PLATFORM}&platform_admin_os=${PLATFORM}&events=${EVENTS}&eum=${EUM}&apm_os=windows%2Clinux%2Calpine-linux%2Cosx%2Csolaris%2Csolaris-sparc%2Caix"

  portal_page="https://download.appdynamics.com/download/downloadfile/?version=${VERSION}&apm=${APPAGENT}&os=${PLATFORM}&platform_admin_os=${PLATFORM}&events=${EVENTS}&eum=${EUM}&apm_os=${PLATFORM}"
 
  http_response=$(curl -s -o ${DOWNLOAD_PAGE_OUTPUT} -w "%{http_code}" -X GET "$portal_page")

  if [ "${http_response}" -ge 400 ] && [ "${http_code}" -lt 600 ]; then
    exit_with_error "bad HTTP response code: ${http_response}" "${ERR_BAD_RESPONSE}"
  fi

  if [ "${http_response}" != "200" ]; then
    exit_with_error "None 200 response code: ${http_response}" "${ERR_GENERIC}"
  fi

  processed_payload=$(cat ${DOWNLOAD_PAGE_OUTPUT} | jq "first(.results[]  | select(.s3_path | test(\"${matchString}\"))) | .")

  readonly d_s3_path=$(echo ${processed_payload} | jq -r .s3_path)
  if [ -z "$d_s3_path" ]; then
    exit_with_error "Could not download your request ${1}. Please ensure that agent version exist in https://download.appdynamics.com " "${ERR_BAD_RESPONSE}"
  fi

  echo $d_s3_path
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

###################################################################################################################
#                                             COMMAND FUNCTIONS                                                   #
###################################################################################################################

# Implements the `download` sub-command. This involves downloading the
# specified agent and verifying its integrity.
#
# Args: [sun-java|ibm-java|machine|machine-win|dotnet] --version VERSION
download() {
  while [ $# -gt 0 ]; do
    case "$1" in
    -v | --version)
      [ -n "${version:-}" ] && exit_bad_args "--version already specified"
      shift
      readonly version="${1:-}"
      ;;
    -u | --url)
      shift
      url="${1:-}"
      ;;
    sun-java | ibm-java | machine | machine-win | dotnet | db | db-win)
      [ -n "${agent:-}" ] && exit_bad_args "multiple agents must be downloaded in separate command invocations"
      readonly agent="${1:-}"
      ;;
    *)
      exit_bad_args "unknown argument: $1"
      ;;
    esac
    shift
  done

  if [ -z "${agent:-}" ] || [ -z "${version:-}" ]; then
    exit_bad_args "missing one or more of agent type and  version"
  fi

  download_options "${agent}"
  readonly s3_path="$(get_download_url ${agent} ${version})"
  download_url="${DEFAULT_DOWNLOAD_SITE}/${s3_path}"
  echo $download_url

  # cleanup
  rm -f ${DOWNLOAD_PAGE_OUTPUT}

  ############# ALL I NEED IN ANSIBLE is the download path ###################

  # Get the archive name.
  # readonly archive_name=$(basename "${download_url}")

  # Actual download: curl the URL.
  #info_msg "Downloading ${agent} agent from ${download_url}"
  #do_curl "${download_url}"

  # Validate the downloaded file.
  # ansible - checksum verification not needed..
  #verify "${archive_name}" "${checksum}"
  ################### ################### ################### ################### ###################
}

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
