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
# Provenance: https://github.com/rawiriblundell/sh_libpath
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_crypto_ssl_view_cert+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_view_cert=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_view_cert: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Display a specific field or the full decoded text of an X.509 certificate.
#   The first argument selects the field; the second is the certificate file.
#   For the 'expiry'/'end' field the second argument may be a remote hostname
#   (port defaults to 443 or may be passed as the third argument).
#
# @arg $1 string Field: algorithm | CN | days | email | expiry | end | fingerprint | issuer | modulus | OrgName | SANs | serial | start | state — or any other value for full text
# @arg $2 string Certificate file path (or hostname for remote expiry check)
#
# @stdout Requested certificate field value or full decoded certificate text
# @exitcode 0 Success
# @exitcode 1 No input provided
# This function absorbs code from
# https://github.com/rawiriblundell/scripts/blob/master/ssl_audit
# (c) 2019 Rawiri Blundell, Datacom Compute.  MIT License.
ssl_view_cert () {
    local _ssl_view_cert_algorithm _ssl_view_cert_host _ssl_view_cert_port _ssl_view_cert_in
    local _ssl_view_cert_exp_epoch _ssl_view_cert_now_epoch _ssl_view_cert_date_str _ssl_view_cert_days
    _ssl_view_cert_in="${2}"

    if (( "${#_ssl_view_cert_in}" == 0 )); then
        printf -- 'ssl_view_cert: %s\n' "No input file provided" >&2
        return 1
    fi

    case "${1}" in
        ([Aa]lgorithm)
            _ssl_view_cert_algorithm=$(
                openssl x509 -text -noout -in "${_ssl_view_cert_in}" | 
                    awk -F ': ' '/Signature Algorithm/{print $2; exit}'
            )

            # Sometimes openssl isn't new enough to recognise a human friendly name
            # and returns an oid instead.  We map these cases here, reference: http://oid-info.com
            case "${_ssl_view_cert_algorithm}" in
                ('1.2.840.10045.4.3.1') _ssl_view_cert_algorithm="ecdsa-with-SHA224" ;;
                ('1.2.840.10045.4.3.2') _ssl_view_cert_algorithm="ecdsa-with-SHA256" ;;
                ('1.2.840.10045.4.3.3') _ssl_view_cert_algorithm="ecdsa-with-SHA384" ;;
                ('1.2.840.10045.4.3.4') _ssl_view_cert_algorithm="ecdsa-with-SHA512" ;;
                (*) : ;;
            esac

            printf -- '%s\n' "${_ssl_view_cert_algorithm:-UNKNOWN}"
        ;;
        (CN|cn|[Cc]ommon[Nn]ame)
            openssl x509 -in "${_ssl_view_cert_in}" -subject -noout -nameopt multiline |
                awk -F '= ' '/commonName/{print $2}' |
                paste -sd "," -
        ;;
        ([Ee]mail)
            openssl x509 -in "${_ssl_view_cert_in}" -subject -noout -nameopt multiline |
                awk -F '= ' '/emailAddress/{print $2}'
        ;;
        ([Ee]xpiry|[Ee]nd)
            # First we test if it's a local file
            if [ -r "${_ssl_view_cert_in}" ]; then
                openssl x509 -in "${_ssl_view_cert_in}" -enddate -noout |
                    sed -e "s/^notAfter=//" -e "s/GMT//" |
                    awk '{printf("%s %02d %d %s\n", $1,$2,$4,$3)}'
            # Otherwise, we assume a connection to a remote host
            else
                _ssl_view_cert_host="${1}"
                _ssl_view_cert_port="${2:-443}"
                printf '\n' | openssl s_client -showcerts -host "${_ssl_view_cert_host}" -port "${_ssl_view_cert_port}" 2>&1 \
                    | openssl x509 -inform pem -noout -enddate \
                    | cut -d "=" -f 2
            fi
        ;;
        ([Ff]ingerprint)
            openssl x509 -in "${_ssl_view_cert_in}" -fingerprint -noout
        ;;
        ([Ii]ssuer)
            openssl x509 -in "${_ssl_view_cert_in}" -issuer -noout |
                sed -e "s/^issuer=//"
        ;;
        ([Mm]odulus)
            openssl x509 -noout -modulus -in "${_ssl_view_cert_in}" | shasum -a 256
        ;;
        ([Oo][Uu]|[Oo]rg|[Oo]rg[Nn]ame)
            openssl x509 -in "${_ssl_view_cert_in}" -subject -noout -nameopt multiline |
                awk -F '= ' '/organizationalUnitName/{print $2}' |
                paste -s -
        ;;
        ([Ss][Aa][Nn][Ss])
            openssl x509 -in "${_ssl_view_cert_in}" -text -noout |
                grep "DNS:" |
                trim |
                paste -sd ' ' - |
                grep .
        ;;
        ([Ss]erial)
            openssl x509 -in "${_ssl_view_cert_in}" -serial -noout |
                sed -e "s/^serial=//"
        ;;
        ([Ss]tart)
            openssl x509 -in "${_ssl_view_cert_in}" -startdate -noout |
                sed -e "s/^notBefore=//" -e "s/GMT//" |
                awk '{printf("%s %02d %d %s\n", $1,$2,$4,$3)}'
        ;;
        ([Dd]ays)
            _ssl_view_cert_date_str=$(openssl x509 -in "${_ssl_view_cert_in}" -enddate -noout | cut -d= -f2)
            # date -d is GNU-specific; test before use, fall back to perl Time::Local
            if date -d "${_ssl_view_cert_date_str}" +%s >/dev/null 2>&1; then
                _ssl_view_cert_exp_epoch=$(date -d "${_ssl_view_cert_date_str}" +%s)
            elif command -v perl >/dev/null 2>&1; then
                _ssl_view_cert_exp_epoch=$(perl -e '
                    use Time::Local;
                    my ($mon,$day,$time,$year) = (split /\s+/, $ARGV[0])[0,1,2,3];
                    my %m = (Jan=>0,Feb=>1,Mar=>2,Apr=>3,May=>4,Jun=>5,
                             Jul=>6,Aug=>7,Sep=>8,Oct=>9,Nov=>10,Dec=>11);
                    my ($h,$mi,$s) = split /:/, $time;
                    print timegm($s,$mi,$h,$day,$m{$mon},$year-1900)."\n";
                ' "${_ssl_view_cert_date_str}")
            else
                printf -- 'ssl_view_cert: %s\n' "days: requires GNU date or perl" >&2
                return 1
            fi
            _ssl_view_cert_now_epoch=$(date +%s)
            _ssl_view_cert_days=$(( (_ssl_view_cert_exp_epoch - _ssl_view_cert_now_epoch) / 86400 ))
            # Human-friendly output when stdout is a terminal; plain integer otherwise
            if [[ -t 1 ]]; then
                printf -- '%d days\n' "${_ssl_view_cert_days}"
            else
                printf -- '%d\n' "${_ssl_view_cert_days}"
            fi
        ;;
        ([Ss]tate)
            case "$(openssl x509 -in "${_ssl_view_cert_in}" -checkend "${3:-0}")" in
                (*'not expire'*)  printf -- '%s\n' "OK" ;;
                (*'will expire')  printf -- '%s\n' "EXPIRED" ;;
            esac
        ;;
        (*)
            openssl x509 -text -noout -in "${_ssl_view_cert_in}"
        ;;
    esac
}
