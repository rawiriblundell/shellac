# shellcheck shell=bash

# Copyright 2022 Rawiri Blundell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
# Provenance: https://github.com/rawiriblundell/shellac
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_sys_sys_virt_status+x}" ] && return 0
_SHELLAC_LOADED_sys_sys_virt_status=1

# @description Determine whether the host is a virtual machine or physical host
#   by inspecting /proc/cpuinfo for hypervisor and virtualisation CPU flags.
#
# @stdout "virtual", "physical", or "unknown"
# @exitcode 0 Always
sys_virt_status() {
  if grep -q hypervisor /proc/cpuinfo; then
    printf -- '%s\n' "virtual"
  elif grep -qE '^flags.*svm|^flags.*vmx' /proc/cpuinfo; then
    printf -- '%s\n' "physical"
  else
    printf -- '%s\n' "unknown"
  fi
}

# @description Detect whether the host is running on Microsoft Azure.
#   Checks for waagent.log containing "Azure" as the primary indicator.
#
# @exitcode 0 Host appears to be on Azure
# @exitcode 1 Host does not appear to be on Azure
is_azure() {
  # All Azure hosts should have waagent.log
  grep -q -m 1 Azure /var/log/waagent.log 2>/dev/null
  # This may be a suitable alternative:
  #dmidecode | grep "String 1: \[MS_VM_CERT"
  # Does not work reliably:
  #blkid | grep -qE 'BEK|KEK' && return "$?"
  # The below might is not reliable, and technically it identifies HyperV:
  #dmesg | grep -q "Hardware name: Microsoft Corporation Virtual Machine/Virtual Machine"
}

# @description Detect whether the host is running on Amazon Web Services (EC2).
#   Checks /sys/hypervisor/uuid, DMI product_uuid, and the instance identity
#   document endpoint. Note: not updated for IMDSv2.
#
# @exitcode 0 Host appears to be on AWS EC2
# @exitcode 1 Host does not appear to be on AWS EC2
# From https://serverfault.com/a/903599
# See also:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/identify_ec2_instances.html
is_aws() {
  local _doc_url _token
  _doc_url="http://169.254.169.254/latest/dynamic/instance-identity/document"
  if grep -q "^ec2" /sys/hypervisor/uuid 2>/dev/null; then
    return 0
  elif grep -q "^EC2" /sys/devices/virtual/dmi/id/product_uuid 2>/dev/null; then
    return 0
  elif command -v curl >/dev/null 2>&1; then
    # Try IMDSv2 first (token-based); fall back to IMDSv1 for older instances
    _token=$(curl -s -m 5 -X PUT \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
      "http://169.254.169.254/latest/api/token" 2>/dev/null)
    if [ -n "${_token}" ]; then
      curl -s -m 5 -H "X-aws-ec2-metadata-token: ${_token}" \
        "${_doc_url}" 2>/dev/null | grep -q availabilityZone && return 0
    else
      curl -s -m 5 "${_doc_url}" 2>/dev/null | grep -q availabilityZone && return 0
    fi
  fi
  return 1
}

# @description Detect the hypervisor or container runtime type.
#   Tries virt-what first, then dmidecode, then falls back to /proc and filesystem heuristics.
#
# @stdout Virtualisation type string, e.g. "virtualbox", "vmware", "xen", "kvm", "qemu", "docker", "podman"
# @exitcode 0 Always
sys_virt_type() {
  local _sys_type

  # virt-what is the gold standard
  if command -v virt-what >/dev/null 2>&1; then
    _sys_type=$(virt-what 2>/dev/null | head -n 1)
  fi

  # If virt-what doesn't exist or doesn't return anything,
  # try the following bank of heuristics based on dmidecode
  # We are NOT going to fully re-implement virt-what, just catch the usual suspects
  if command -v dmidecode >/dev/null 2>&1; then
    case "$(LANG=C dmidecode 2>&1 | grep -E "Vendor:|Manufacturer:|Product Name:")" in
      (*Alibaba*)      _sys_type="alibaba_cloud" ;;
      (*Amazon*EC2*)   _sys_type="aws" ;;
      (*BHYVE*)        _sys_type="bhyve" ;;
      (*innotek*GmbH*) _sys_type="virtualbox" ;;
      (*KVM*)          _sys_type="kvm" ;;
      (*Microsoft*)    _sys_type="hyperv" ;;
      (*VMware*)       _sys_type="vmware" ;;
      (*Xen*)          _sys_type="xen" ;;
      (*)              : ;;
    esac
  fi
 
  # If we get to this point, then we're getting really esoteric
  if [[ -z "${_sys_type}" ]]; then
    if grep -qi "QEMU Virtual CPU" /proc/cpuinfo 2>/dev/null; then
      _sys_type="qemu"
    elif grep -qi "^KVM$" /sys/devices/virtual/dmi/id/product_name 2>/dev/null; then
      _sys_type="kvm"
    elif [[ -f /.dockerenv ]]; then
      _sys_type="docker"
    elif [[ -f /run/.containerenv ]]; then
      _sys_type="podman"
    fi
  fi

  printf -- '%s\n' "${_sys_type:-unknown}"
}
