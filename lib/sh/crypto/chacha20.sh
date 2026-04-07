#!/bin/bash
# SPDX-License-Identifier: MIT

[ -n "${_SHELLAC_LOADED_crypto_chacha20+x}" ] && return 0
_SHELLAC_LOADED_crypto_chacha20=1
requires BASH43
# Copyright (C) 2020 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.


# @internal
rol() {
	printf -- '%s\n' "$(( (($1 << $2) | ($1 >> (32 - $2))) & 0xffffffff ))"
}

# @internal
quarter_round() {
	local -n x=$1; shift
	x[$1]=$(( (x[$1] + x[$2]) & 0xffffffff ))
	x[$4]=$(rol $(( (x[$4] ^ x[$1]) & 0xffffffff )) 16)
	x[$3]=$(( (x[$3] + x[$4]) & 0xffffffff ))
	x[$2]=$(rol $(( (x[$2] ^ x[$3]) & 0xffffffff )) 12)
	x[$1]=$(( (x[$1] + x[$2]) & 0xffffffff ))
	x[$4]=$(rol $(( (x[$4] ^ x[$1]) & 0xffffffff )) 8)
	x[$3]=$(( (x[$3] + x[$4]) & 0xffffffff ))
	x[$2]=$(rol $(( (x[$2] ^ x[$3]) & 0xffffffff )) 7)
}

# @internal
c() {
	printf -- '%s\n' "$(( ($1 << 2) + $2 ))"
}

# @internal
double_round() {
	quarter_round $1 $(c 0 0) $(c 1 0) $(c 2 0) $(c 3 0)
	quarter_round $1 $(c 0 1) $(c 1 1) $(c 2 1) $(c 3 1)
	quarter_round $1 $(c 0 2) $(c 1 2) $(c 2 2) $(c 3 2)
	quarter_round $1 $(c 0 3) $(c 1 3) $(c 2 3) $(c 3 3)
	quarter_round $1 $(c 0 0) $(c 1 1) $(c 2 2) $(c 3 3)
	quarter_round $1 $(c 0 1) $(c 1 2) $(c 2 3) $(c 3 0)
	quarter_round $1 $(c 0 2) $(c 1 3) $(c 2 0) $(c 3 1)
	quarter_round $1 $(c 0 3) $(c 1 0) $(c 2 1) $(c 3 2)
}

# @internal
twenty_rounds() {
	double_round $1
	double_round $1
	double_round $1
	double_round $1
	double_round $1
	double_round $1
	double_round $1
	double_round $1
	double_round $1
	double_round $1
}

# @internal
le() {
	printf -- '%d %d %d %d\n' \
		"$(( ($1 >> 0) & 0xff))" "$(( ($1 >> 8) & 0xff))" \
		"$(( ($1 >> 16) & 0xff))" "$(( ($1 >> 24) & 0xff))"
}

# @internal
one_block() {
	local -n state=$1
	local -n stream=$2
	local block=( ${state[@]} )
	twenty_rounds block
	for (( i=0; i < 16; i++ )); do
		stream+=( $(le $(( (state[$i] + block[$i]) & 0xffffffff )) ) )
	done
	state[12]=$(( (state[12] + 1) & 0xffffffff ))
	(( state[12] != 0 )) || state[13]=$(( (state[13] + 1) & 0xffffffff ))
}

# @internal
dehex() {
	printf -- '%s\n' "$(( (0x${1:0:2} << 0) | (0x${1:2:2} << 8) | (0x${1:4:2} << 16) | (0x${1:6:2} << 24) ))"
}

# @description Encrypt or decrypt data using the ChaCha20 stream cipher.
#   Pure bash implementation by Jason A. Donenfeld. Symmetric: encrypting
#   ciphertext with the same key and nonce yields plaintext, and vice versa.
#
# @arg $1 string 64-character hex key (256-bit)
# @arg $2 int 64-bit numeric nonce
# @arg $3 string Hex-encoded input (ciphertext or plaintext)
#
# @example
#   chacha20 "$key" "$nonce" "$ciphertext"   # => hex plaintext
#
# @stdout Hex-encoded output (decrypted or encrypted)
# @exitcode 0 Always
chacha20() {
	local cstate=(
		1634760805 857760878 2036477234 1797285236
		$(dehex ${1:0:8}) $(dehex ${1:8:8}) $(dehex ${1:16:8}) $(dehex ${1:24:8})
		$(dehex ${1:32:8}) $(dehex ${1:40:8}) $(dehex ${1:48:8}) $(dehex ${1:56:8})
		0 0 $(( $2 & 0xffffffff )) $(( ($2 >> 32) & 0xffffffff ))
	)
	local ciphertext="$3"
	local n=0
	while true; do
		[[ -n ${ciphertext:$n} ]] || { printf -- '\n'; return 0; }
		local cstream=()
		one_block cstate cstream
		for (( i=0; i < 64; i++ )); do
			[[ -n ${ciphertext:$n} ]] || { printf -- '\n'; return 0; }
			printf '%02x' $(( cstream[$i] ^ 0x${ciphertext:$n:2} ))
			(( n+=2 ))
		done
	done
}

# @internal
test_vector() {
	local ciphertext="d42efa92e92968b7542cf7a42db750b5c5b29d175e0aca37bf60aed298e9fa596762e6430c7780823361a3ffc1a08f56bcec654388a5ff516430ee34b75c2868c352d2ac782aa610b8b24c804f99b236948f66cba191ed06426dc1ae5593dd939e88347f98ebbe61f9a90fd9c487d5efcc718c0ecead02cfa261dfb1fe3bdcc058b571a183c9b4af9d5412cdea06d64ee5270cc3bba80a8175c3c9d4353e539faa20c068392c96395381da070f44a5470eb3870d1bc1e54135125896698a1aa39d3dd4b18e1f9687dad319e2b13a1974a0009f4dbccb0ce9ec10df2a88dc3051465653986a2614055481550b3c85dd33811129824635e1db597b"
	local plaintext="646cda7fd4a92a5e22ae8d67dbeefdd0448017b2e387ad5715cb8864c0f1493dfabea89f12c3575670a5c56bf1abd5de77926a5603f5210db6c4cc62443fb1c1614190b2d5b8f357fbc26b2558c8452072296f9db5814d2bb2899e9153971cd93d79dc14ae017375f0cad5ab625c7a7d3ffe227deee2cb7655ec06dd414718621d57d0d6b60f4bfc7919f4d63786181f980d9e152db69a8a8c80222f82c4c736fafa07bdc22ae2ea93c8b29033f2ee4b1bf4379213bbe2cee303cf0794ab9ac9ff83693ada2cd0473d6c1a606847b93652dd16ef6cbf54117262ce8c9d90a02506923e127e1a1de5a271ce1c4c6a7cdc3de36e489db3647d7840"
	local key="a92075897e378548a3fb7be830a7e36ea6c17117c16c9bc2def0a719eccec653"
	local nonce=5394271251748129296

	[[ $(chacha20 "$key" "$nonce" "$ciphertext") == "$plaintext" ]] && printf -- '%s\n' pass || printf -- '%s\n' fail
	[[ $(chacha20 "$key" "$nonce" "$plaintext") == "$ciphertext" ]] && printf -- '%s\n' pass || printf -- '%s\n' fail
}

test_vector
