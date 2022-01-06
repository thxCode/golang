#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Kustomize variables helpers. These functions need the
# following variables:
#
#    KUSTOMIZE_VERSION  -  The go kubstomize version, default is v3.8.7.

kustomize_version=${KUSTOMIZE_VERSION:-"v3.8.7"}

function cos::kustomize::bin() {
  local bin="kustomize"
  if [[ -f "${ROOT_SBIN_DIR}/kustomize" ]]; then
    bin="${ROOT_SBIN_DIR}/kustomize"
  fi
  echo "${bin}"
}

function cos::kustomize::install() {
  tmp_dir=$(mktemp -d)
  pushd "${tmp_dir}" >/dev/null || exit 1
  go mod init tmp
  GOBIN="${ROOT_SBIN_DIR}" GO111MODULE=on go get "sigs.k8s.io/kustomize/kustomize/v3@${kustomize_version}"
  rm -rf "${tmp_dir}"
  popd >/dev/null || return
}

function cos::kustomize::validate() {
  # shellcheck disable=SC2046
  if [[ -n "$(command -v $(cos::kustomize::bin))" ]]; then
    if [[ $($(cos::kustomize::bin) version 2>&1 | cut -d " " -f 1 2>&1 | sed 's/.*\///g') == "${kustomize_version}" ]]; then
      return 0
    fi
  fi

  cos::log::info "installing kustomize ${kustomize_version}"
  if cos::kustomize::install; then
    cos::log::info "controller-gen: $($(cos::kustomize::bin) version)"
    return 0
  fi
  cos::log::error "no kustomize available"
  return 1
}

function cos::kustomize::generate() {
  if ! cos::kustomize::validate; then
    cos::log::error "cannot execute kustomize as it hasn't installed"
    return
  fi

  cos::log::debug "kustomize build $*"
  $(cos::kustomize::bin) build "$@"
}
