#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Terraform variables helpers. These functions need the
# following variables:
#
#             TERRAFORM_VERSION  -  The terraform version for running, default is v0.14.9.
# TERRAFORM_PLUGIN_DOCS_VERSION  -  The terraform docs plugin for running, default is v0.3.1.

terraform_version=${TERRAFORM_VERSION:-"v0.14.9"}
log_colorful="${LOG_COLORFUL:-"true"}"

function cos::terraform::bin() {
  local bin="terraform"
  if [[ -f "${ROOT_SBIN_DIR}/terraform" ]]; then
    bin="${ROOT_SBIN_DIR}/terraform"
  fi
  echo "${bin}"
}

function cos::terraform::install() {
  curl -fL "https://releases.hashicorp.com/terraform/${terraform_version#v}/terraform_${terraform_version#v}_$(cos::util::get_os)_$(cos::util::get_arch).zip" -o /tmp/terraform.zip
  unzip -o /tmp/terraform.zip -d /tmp
  chmod +x /tmp/terraform && mv /tmp/terraform "${ROOT_SBIN_DIR}/terraform"
}

function cos::terraform::validate() {
  # shellcheck disable=SC2046
  if [[ -n "$(command -v $(cos::terraform::bin))" ]]; then
    if [[ $($(cos::terraform::bin) version 2>&1) =~ "Terraform ${terraform_version}" ]]; then
      return 0
    fi
  fi

  cos::log::info "installing terraform"
  if cos::terraform::install; then
    cos::log::info "terraform: $($(cos::terraform::bin) version 2>&1)"
    return 0
  fi
  cos::log::error "no terraform available"
  return 1
}

function cos::terraform::init() {
  if ! cos::terraform::validate; then
    cos::log::error "cannot execute terraform as it hasn't installed"
    return
  fi

  cos::log::debug "terraform init -upgrade $*"
  if [[ ${log_colorful} == "true" ]]; then
    $(cos::terraform::bin) init -upgrade "$@"
  else
    $(cos::terraform::bin) init -no-color -upgrade "$@"
  fi
}

function cos::terraform::plan() {
  if ! cos::terraform::validate; then
    cos::log::error "cannot execute terraform as it hasn't installed"
    return
  fi

  cos::log::debug "terraform plan $*"
  if [[ ${log_colorful} == "true" ]]; then
    $(cos::terraform::bin) plan "$@"
  else
    $(cos::terraform::bin) plan -no-color "$@"
  fi
}

function cos::terraform::apply() {
  if ! cos::terraform::validate; then
    cos::log::error "cannot execute terraform as it hasn't installed"
    return
  fi

  cos::log::debug "terraform apply -auto-approve $*"
  if [[ ${log_colorful} == "true" ]]; then
    $(cos::terraform::bin) apply -auto-approve "$@"
  else
    $(cos::terraform::bin) apply -no-color -auto-approve "$@"
  fi
}

function cos::terraform::destroy() {
  if ! cos::terraform::validate; then
    cos::log::error "cannot execute terraform as it hasn't installed"
    return
  fi

  cos::log::debug "terraform destroy -auto-approve $*"
  if [[ ${log_colorful} == "true" ]]; then
    $(cos::terraform::bin) destroy -auto-approve "$@"
  else
    $(cos::terraform::bin) destroy -no-color -auto-approve "$@"
  fi
}
