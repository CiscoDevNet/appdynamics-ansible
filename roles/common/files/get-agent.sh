#!/usr/bin/env sh

# This script is not officially supported by AppDynamics 
# Author: Israel Ogbole 

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

DOWNLOAD_PAGE_OUTPUT="tmp.json"

#download page search params
_app_agent=""
_os_platform=""
_eum=""
_events=""
_version=""

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
  echo "  download AGENT                       Agent to download (choices: sun-java | java | sun-java8 | java8 | ibm-java | machine | machine-win | dotnet | dotnet-core | db | db-win)"
  echo "    -v, --version  version             Version number for the supplied agent"
  echo "    -d, --dryrun                       Rturns only the download URL if specificed, it is recommended to use this arg for provisioning tools such as ansible, chef, etc "
  echo
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
# with `ERR_UNSUPPORTED_PLATFORM`.
check_platform_compatibility() {
  if [ "${OS}" != "Linux" ] || [ "${ARCH}" != "x86_64" ]; then
    exit_with_error "Unsupported operating system or machine architecture: ${OS} ${ARCH}. \
      Cannot use get-agent" ${ERR_UNSUPPORTED_PLATFORM}
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
download_options() {
  if [ "$1" = "sun-java" -o "$1" = "java" ]; then
    _app_agent="jvm%2Cjava-jdk8" #_app_agent="jvm"
    _finder="sun-jvm"
    _os_platform="linux"
  elif [ "$1" = "sun-java8" -o "$1" = "java8" ]; then
    _app_agent="jvm%2Cjava-jdk8"
    _finder="java-jdk8"
    _os_platform="linux"
  elif [ "$1" = "ibm-java" ]; then
    _app_agent="jvm%2Cjava-jdk8"
    _finder="ibm-jvm"
    _os_platform="linux"
  elif [ "$1" = "machine" ]; then
    _app_agent="machine"
    _os_platform="linux"
    _finder="machineagent-bundle-64bit-linux"
  elif [ "$1" = "machine-win" ]; then
    _app_agent="machine"
    _os_platform="windows"
    _finder="machineagent-bundle-64bit-windows"
  elif [ "$1" = "dotnet" ]; then
    _app_agent="dotnet"
    _finder="dotnet"
    _os_platform="windows"
  
  elif [ "$1" = "dotnet-core" ]; then
    _app_agent="dotnet,dotnet-core"
    _finder="AppDynamics-DotNetCore-linux-x64"
    _os_platform="linux"

  elif [ "$1" = "db" -o ]; then
    _app_agent="db"
    _finder="db-agent"
    _os_platform="linux"
  elif [ "$1" = "db-win" ]; then
    _app_agent="db"
    _finder="db-agent-winx64"
    _os_platform="windows"
  else
    exit_bad_args "unknown agent type: $1"
  fi
}


# Returns the download URL for the provided agent and version. Incorrect
# argument results in exit with `ERR_BAD_ARGS`.
#
# Args:
#   $1 - agent type 
#   $3 - agent version
# Returns:
#   the downlod URL for the specified agent and version.
get_download_url() {
  _version="$2"
  #portal_page="https://download.appdynamics.com/download/downloadfile/?version=${_version}&apm=${_app_agent}&os=${_os_platform}&platform_admin_os=${_os_platform}&events=${_events}&eum=${_eum}&apm_os=windows%2Clinux%2Calpine-linux%2Cosx%2Csolaris%2Csolaris-sparc%2Caix"

  portal_page="https://download.appdynamics.com/download/downloadfile/?version=${_version}&apm=${_app_agent}&os=${_os_platform}&platform_admin_os=${_os_platform}&events=${_events}&eum=${_eum}&apm_os=${_os_platform}"

  http_response=$(curl -s -o ${DOWNLOAD_PAGE_OUTPUT} -w "%{http_code}" -X GET "$portal_page")

  if [ "${http_response}" -ge 400 ] && [ "${http_code}" -lt 600 ]; then
    exit_with_error "bad HTTP response code: ${http_response}" "${ERR_BAD_RESPONSE}"
  fi

  if [ "${http_response}" != "200" ]; then
    exit_with_error "None 200 response code: ${http_response}" "${ERR_GENERIC}"
  fi

  processed_payload=$(cat ${DOWNLOAD_PAGE_OUTPUT} | jq "first(.results[]  | select(.s3_path | test(\"${_finder}\"))) | .")
  readonly d_s3_path=$(echo ${processed_payload} | jq -r .s3_path)

  if [ -z "$d_s3_path" ] || [ "$d_s3_path" = "" ]; then
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


# Verifies that the agent archive file is actually downloaded AND the on-disk
# with `ERR_MISSING_ARCHIVE` if the specified archive file is missing and
#
# Args:
#   $1 - name of the downloaded archive file
verify() {
  readonly archive="$1"

  # Check if we actually have a file.
  if [ ! -f "${archive_name}" ]; then
    exit_with_error "missing archive: ${archive}" "${ERR_MISSING_ARCHIVE}"
  fi
  info_msg "Successfully downloaded ${archive}"
}


# Extract the spicified agent into specified directory
# Args:
#   $1 - name prefix of the specified agent.
#   $2 - directory name. Default current directory.
#   $3 - exit if file does not exists. Default : true
do_unzip() {
  agent_directory_name=${2:-}
  fail_if_not_exists=${3:-true}
  agent_artifact=$1
  if [ -f "${agent_artifact}" ]; then
    if [ ! -d "${agent_directory_name}" ]; then
      info_msg "Extracting ${agent_artifact}..."
      if ! unzip -q -o -d "${agent_directory_name}" "${agent_artifact}"; then
        exit_with_error "Failed to extract ${agent_artifact}" ${ERR_INTEGRITY}
      fi
    fi
  elif ${fail_if_not_exists}; then
    exit_with_error "Failed to discover agent artifact with prefix ${agent_artifact}" ${ERR_MISSING_ARCHIVE}
  fi
}

###################################################################################################################
#                                             COMMAND FUNCTIONS                                                   #
###################################################################################################################

# Implements the `download` sub-command. This involves downloading the
# specified agent and verifying its integrity.
#
# Args: [agent-type] --version VERSION --dryrun
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
    -d | --dryrun)
      shift
      dryrun="true"
      ;;
    sun-java | java | sun-java8 | java8 | ibm-java | machine | machine-win | dotnet | dotnet-core | db | db-win)
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

  if [ -z "${dryrun:-}" ]; then
    dryrun="false"
  fi

  #Call download options
  download_options "${agent}"
  readonly s3_download_uri="$(get_download_url ${agent} ${version})"

  if [ -z "$s3_download_uri" ] || [ "$s3_download_uri" = "" ]; then
    exit_with_error "Could not download your request . Please ensure that agent version exist in https://download.appdynamics.com " "${ERR_BAD_RESPONSE}"

  elif [ "${dryrun}" = "true" ]; then
    download_url="${DEFAULT_DOWNLOAD_SITE}/${s3_download_uri}"
    echo $download_url
    cleanup
  else
    download_url="${DEFAULT_DOWNLOAD_SITE}/${s3_download_uri}"
    # Get the archive name.
    readonly archive_name=$(basename "${download_url}")
    do_curl "${download_url}"
    verify "${archive_name}"
    do_unzip "${archive_name}" "${agent}-${version}"
   cleanup
  fi

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
