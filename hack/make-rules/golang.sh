#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
source "${ROOT_DIR}/hack/lib/init.sh"
source "${ROOT_DIR}/hack/constant.sh"

mkdir -p "${ROOT_DIR}/bin"
mkdir -p "${ROOT_DIR}/dist"

function terraform::init() {
  if [[ ! -f "${ROOT_DIR}/.terraform.lock.hcl" ]]; then
    cos::terraform::init "$@"
  fi

  cat <<EOF > golang.auto.tfvars
access_key = "${ACCESS_KEY:-}"
secret_key = "${SECRET_KEY:-}"
host_password = "${HOST_PASSWORD:-}"
image_registry_username = "${DOCKER_USERNAME:-}"
image_registry_password = "${DOCKER_PASSWORD:-}"
EOF
}

function generate() {
  cos::log::info "generating golang..."

  cos::log::info "...done"
}

function mod() {
  [[ "${1:-}" != "only" && "${1:-}" != "o" ]] && generate
  cos::log::info "downloading dependencies for golang..."

  cos::log::info "...done"
}

function lint() {
  [[ "${1:-}" != "only" && "${1:-}" != "o" ]] && mod
  cos::log::info "linting golang..."

  cos::log::info "...done"
}

function build() {
  [[ "${1:-}" != "only" && "${1:-}" != "o" ]] && lint
  cos::log::info "building golang(${GIT_VERSION},${GIT_COMMIT},${GIT_TREE_STATE},${BUILD_DATE})..."

  cos::log::info "...done"
}

function package() {
  [[ "${1:-}" != "only" && "${1:-}" != "o" ]] && build
  cos::log::info "packaging golang..."

  terraform::init "${ROOT_DIR}/terraform"

  local err_msg=""
  set +o pipefail
  if ! cos::terraform::apply "${ROOT_DIR}/terraform"; then
    err_msg="failed to package images"
  fi
  set -o pipefail

  if [[ "${err_msg}" != "" ]]; then
    cos::log::error "failed to execute terraform apply, going to destory all created resources."
    cos::terraform::destroy "${ROOT_DIR}/terraform" 2>&1 >/dev/null
    cos::log::fatal "${err_msg}"
  fi
  
  cos::log::info "...done"
}

function deploy() {
  [[ "${1:-}" != "only" && "${1:-}" != "o" ]] && package
  cos::log::info "deploying golang..."

  terraform::init "${ROOT_DIR}/terraform"

  local err_msg=""  
  set +o pipefail
  if ! cos::terraform::apply "${ROOT_DIR}/terraform"; then
    err_msg="failed to deploy images"
    cos::log::error "failed to execute terraform apply, going to destory all created resources."
  fi
  set -o pipefail

  cos::terraform::destroy "${ROOT_DIR}/terraform" 2>&1 >/dev/null
  if [[ "${err_msg}" != "" ]]; then
    cos::log::fatal "${err_msg}"
  fi

  cos::log::info "...done"
}

function test() {
  [[ "${1:-}" != "only" && "${1:-}" != "o" ]] && build
  cos::log::info "running unit tests for golang..."

  cos::log::info "...done"
}

function verify() {
  [[ "${1:-}" != "only" && "${1:-}" != "o" ]] && test
  cos::log::info "running integration tests for golang..."

  cos::log::info "...done"
}

function e2e() {
  [[ "${1:-}" != "only" && "${1:-}" != "o" ]] && verify
  cos::log::info "running E2E tests for golang..."

  cos::log::info "...done"
}

function entry::dapper() {
  BY="" cos::dapper::run -C="${ROOT_DIR}" -f="Dockerfile.dapper" "golang" "$@"
}

function entry::default() {
  local stages="${1:-build}"
  shift $(($# > 0 ? 1 : 0))

  IFS="," read -r -a stages <<<"${stages}"
  local commands=$*
  if [[ ${#stages[@]} -ne 1 ]]; then
    commands="only"
  fi

  for stage in "${stages[@]}"; do
    cos::log::info "# make golang ${stage} ${commands}"
    case ${stage} in
    g | gen | generate) generate "${commands}" ;;
    m | mod) mod "${commands}" ;;
    l | lint) lint "${commands}" ;;
    b | build) build "${commands}" ;;
    p | pkg | package) package "${commands}" ;;
    d | dep | deploy) deploy "${commands}" ;;
    t | test) test "${commands}" ;;
    v | ver | verify) verify "${commands}" ;;
    e | e2e) e2e "${commands}" ;;
    *) cos::log::fatal "unknown action '${stage}', select from generate,mod,lint,build,test,verify,package,deploy,e2e" ;;
    esac
  done
}

case ${BY:-} in
dapper) entry::dapper "$@" ;;
*) entry::default "$@" ;;
esac
