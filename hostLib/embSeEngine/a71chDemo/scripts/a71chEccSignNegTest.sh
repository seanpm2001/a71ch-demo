#!/bin/bash

# FILE: a71chEccSignNegTest.sh (A71CH specific demo script)
# - Illustrates the signing of a file with ECDSA using a private key stored in Secure Element
# - Illustrates the verification of a signature using a public key stored in Secure Element
# Preconditions
# - Invoke from directory where this script is stored
# - Properly prepare Secure Element (invoke a71chPrepareEcc.sh)
# - OpenSSL Engine must have handover enabled both for Public and Private keys
# Postconditions
# - *.bin files are created in current directory

# GLOBAL VARIABLES
# ----------------

OPENSSL_CONF_A71CH=/etc/ssl/opensslA71CH_i2c.cnf
OPENSSL_A71CH="openssl"
probeExec="../../../../linux/a71chConfig_i2c_imx"

A71CH_ECC_SIGN_NEG_TEST_SCRIPT_VER="1.0"

#
# Test specific files and directories
# -----------------------------------
signKeyA="../eccRef/ecc_key_kp_0_ref.pem"
# Verify key may only contain public key part of "../ecc/ecc_key_kp_0.pem" 
# when using -verify option of openssl's dgst command
verifyKeyHostA="../ecc/ecc_key_kp_pubonly_0.pem"

signKeyHostB="../ecc/ecc_key_pub_0.pem"
verifyKeyPubOnlyB="../ecc/ecc_key_pub_pubonly_0.pem"
verifyKeyRefB="../eccRef/ecc_key_pub_0_ref.pem"

ecc_key_kp_1="../ecc/ecc_key_kp_1.pem"
signKeyC="../eccRef/ecc_key_kp_1_ref.pem"
verifyKeyHostC="../ecc/ecc_key_kp_pubonly_1.pem"

verifyKeyRef_IndexOutOfRange="../eccRef/ecc_key_pub_3_ref.pem"
signKeyRef_IndexOutOfRange="../eccRef/ecc_key_kp_4_ref.pem"

# Set global variables to default values
gExecMsg=""
gRetValue=0

# UTILITY FUNCTIONS
# -----------------
# execCommand will stop script execution when the program executed does return gRetValue (0 by default) to the shell
execCommand () {
	local command="$*"
	echo ">> ${gExecMsg}"
	echo ">> ${command}"
	${command}
	local nRetProc="$?"
	if [ ${nRetProc} -ne ${gRetValue} ]
	then
		echo "\"${command}\" failed to run successfully, returned ${nRetProc}"
		echo "** Demo failed **"
		exit 2
	fi
	echo ""
	# Set global variables to default values
	gExecMsg=""
	gRetValue=0
} 

# --------------------------------------------------------------
# Start of program - Ensure an A71CH is connected to your system.
# --------------------------------------------------------------
echo "A71CH ECC Sign/Verify demo script (Rev.${A71CH_ECC_SIGN_NEG_TEST_SCRIPT_VER})."

# Sanity check on existence probeExec
# -----------------------------------
stringarray=($probeExec)
if [ "${stringarray[0]}" = "sudo" ]; then
	if [ ! -e ${stringarray[1]} ]; then
		echo "Can't find program executable ${stringarray[1]}"
		exit 3
	fi
else
	if [ ! -e ${stringarray[0]} ]; then
		echo "Can't find program executable ${stringarray[0]}"
		exit 3
	fi
fi

# Check whether a file to sign was specified as argument
# ------------------------------------------------------
if [ $# -lt 1 ]; then
	echo "Provide the file you want to sign as argument"
	exit 1
fi

# ECDSA combined with SHA1 (Sign on A71CH)
# ----------------------------------------
echo "** SHA1 on Host - Sign on A71CH (_0 keys) **"
gExecMsg="Sign ${1} on A71CH using key (ref) ${signKeyA}"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -ecdsa-with-SHA1 -sign ${signKeyA} -out signature_of_sha1.bin ${1}"

gExecMsg="Verify with standard OpenSSL using key ${verifyKeyHostA}"
unset OPENSSL_CONF
execCommand "openssl dgst -sha1 -verify ${verifyKeyHostA} -signature signature_of_sha1.bin ${1}"
	
gExecMsg="Verify - with engine in loop - using key ${verifyKeyHostA}; call is redirected by engine to standard OpenSSL (no verify key matches)"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha1 -verify ${verifyKeyHostA} -signature signature_of_sha1.bin ${1}"

# ECDSA combined with SHA1 (Sign on Host)
# ----------------------------------------
echo "** SHA1 on Host - Sign on Host (_0 keys) **"
gExecMsg="Sign ${1} on Host using key (ref) ${signKeyHostB}"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -ecdsa-with-SHA1 -sign ${signKeyHostB} -out signature_of_sha1.bin ${1}"

gExecMsg="Verify with standard OpenSSL using key ${verifyKeyPubOnlyB}"
unset OPENSSL_CONF
execCommand "openssl dgst -sha1 -verify ${verifyKeyPubOnlyB} -signature signature_of_sha1.bin ${1}"
	
gExecMsg="Verify - with engine in loop - using key ${verifyKeyRefB}"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha1 -prverify ${verifyKeyRefB} -signature signature_of_sha1.bin ${1}"

# ECDSA combined with SHA256 (Sign on A71CH)
# ------------------------------------------
echo "** SHA256 on Host - Sign on A71CH (_0 keys) **"
gExecMsg="Sign ${1} on A71CH using key (ref) ${signKeyA}"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha256 -sign ${signKeyA} -out signature_of_sha256.bin ${1}"

gExecMsg="Verify with standard OpenSSL:"
unset OPENSSL_CONF
execCommand "openssl dgst -sha256 -verify ${verifyKeyHostA} -signature signature_of_sha256.bin ${1}"

# ECDSA combined with SHA256 (Sign on Host)
# -----------------------------------------
echo "** SHA256 on Host - Sign on Host (_0 keys) **"
gExecMsg="Sign ${1} on Host using key ${signKeyHostB}"
unset OPENSSL_CONF
execCommand "openssl dgst -sha256 -sign ${signKeyHostB} -out host_signature_of_sha256.bin ${1}"

gExecMsg="(Negative test) Verify on A71CH, using the wrong signature file"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
gRetValue=1
execCommand "${OPENSSL_A71CH} dgst -sha256 -prverify ${verifyKeyRefB} -signature signature_of_sha256.bin ${1}"

gExecMsg="Verify on A71CH (refkey=${verifyKeyRefB})"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha256 -prverify ${verifyKeyRefB} -signature host_signature_of_sha256.bin ${1}"

gExecMsg="Verify on A71CH (key=${signKeyHostB}) - use value match"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha256 -prverify ${signKeyHostB} -signature host_signature_of_sha256.bin ${1}"

gExecMsg="Verify on A71CH (pub only key=${verifyKeyPubOnlyB}) - use value match"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha256 -verify ${verifyKeyPubOnlyB} -signature host_signature_of_sha256.bin ${1}"

gExecMsg="(Negative test) Verify on A71CH (pub only key=${verifyKeyHostA}) - wrong key, SW handover"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
gRetValue=1
execCommand "${OPENSSL_A71CH} dgst -sha256 -verify ${verifyKeyHostA} -signature host_signature_of_sha256.bin ${1}"

gExecMsg="(Negative test) Verify on A71CH (refkey=${verifyKeyRef_IndexOutOfRange}): Invalid reference key, index out of range"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
gRetValue=1
execCommand "${OPENSSL_A71CH} dgst -sha256 -prverify ${verifyKeyRef_IndexOutOfRange} -signature host_signature_of_sha256.bin ${1}"

# Prepare negative test: Erase public key on index 0
execCommand "${probeExec} erase pub -x 0"

gExecMsg="(Negative test) Verify on A71CH (refkey=${verifyKeyRefB}) - but referenced key has been erased"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
gRetValue=1
execCommand "${OPENSSL_A71CH} dgst -sha256 -prverify ${verifyKeyRefB} -signature host_signature_of_sha256.bin ${1}"

# Restore the public key on index 0
execCommand "${probeExec} set pub -x 0 -k ${signKeyHostB}"

gExecMsg="Verify on A71CH (refkey=${verifyKeyRefB}) - Note: referenced key has been restored"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha256 -prverify ${verifyKeyRefB} -signature host_signature_of_sha256.bin ${1}"

# ECDSA combined with SHA256 (Sign on A71CH)
# Using _1 keys
# ------------------------------------------
echo "** SHA256 on Host - Sign on A71CH (_1 keys) **"
gExecMsg="Sign ${1} on A71CH using key (ref) ${signKeyC}"
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha256 -sign ${signKeyC} -out signature_of_sha256.bin ${1}"

gExecMsg="Verify with standard OpenSSL:"
unset OPENSSL_CONF
execCommand "openssl dgst -sha256 -verify ${verifyKeyHostC} -signature signature_of_sha256.bin ${1}"

# ECDSA combined with SHA256 (Sign on A71CH - Additional negative tests)
# ----------------------------------------------------------------------
gExecMsg="(Neg Test) Sign ${1} on A71CH (refkey=${signKeyRef_IndexOutOfRange}): Invalid reference key, index out of range"
gRetValue=1
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha256 -sign ${signKeyRef_IndexOutOfRange} -out signature_of_sha256.bin ${1}"

# Prepare negative test: Erase key pair on index 1
execCommand "${probeExec} erase pair -x 1"

gExecMsg="(Neg Test) Sign ${1} on A71CH (refkey=${signKeyC}): Keypair on Index 1 has been erased"
gRetValue=1
export OPENSSL_CONF=${OPENSSL_CONF_A71CH}
execCommand "${OPENSSL_A71CH} dgst -sha256 -sign ${signKeyC} -out signature_of_sha256.bin ${1}"

# Put back the key pair on index 1
execCommand "${probeExec} set pair -x 1 -k ${ecc_key_kp_1}"

# gExecMsg="Verify with standard OpenSSL:"
# unset OPENSSL_CONF
# execCommand "openssl dgst -sha256 -verify ${verifyKeyHostC} -signature signature_of_sha256.bin ${1}"

echo "** Negative (sign) test completed successfully (Rev.${A71CH_ECC_SIGN_NEG_TEST_SCRIPT_VER}) **"
