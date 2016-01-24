#!/bin/bash

#
# AUTHOR: Andy Savage <andy@savage.hk>
# GITHUB: https://gist.github.com/hongkongkiwi/cfef6910c5c644eaebc9
# PURPOSE: After building one or more packages in OpenWRT this script signs them with a key file
#          this can then be easily used in opkg to verify signatures.
#

LOCAL_PUB="key.pub"
SCRIPT=$(readlink -f $0)
SCRIPT_PATH=`dirname $SCRIPT`
ABSOLUTE_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN_DIR="${1:-${ABSOLUTE_SCRIPT_PATH}/bin}"
USIGN="$SCRIPT_PATH/signify"
KEY_DIR="${2:-${ABSOLUTE_SCRIPT_PATH}/keys}"
KEY="${KEY_DIR}/mime.key"
PUB="${KEY_DIR}/mime.pub"

# NOTE: When using debian install the signify-openbsd package
# You can generate your own ssl keys using signify-openbsd -G -s mime.key -p mime.pub -n
# All credit to here: http://www.karl.idv.hk/tag/openwrt

command -v "$USIGN" >/dev/null 2>&1 || { echo >&2 "I require 'signify' but it's not installed.  Aborting."; exit 1; }

if [ "$BIN_DIR" == "-h" ] || [ "$BIN_DIR" == "--help" ]; then
	echo "USAGE: $0 <bin_dir>"
	exit 0
fi

if [ ! -f "$KEY" ] || [ ! -f "$PUB" ]; then
        echo "Could not find private key or public key files.  Aborting."
	echo "You can genereate a keypair using:"
	echo "\t$USIGN -G -n -p mime.pub -s mime.key"
	exit 1
fi

if [ ! -d "$BIN_DIR" ]; then
        echo "$BIN_DIR is not a valid directory to find package files.  Aborting."
        exit 1
fi

PACKAGES_COUNT=`find "$BIN_DIR" -name "Packages" | wc -l`

if [[ $PACKAGES_COUNT == 0 ]]; then
	echo "Looking in $BIN_DIR but we couldn't find any packages to sign. Aborting."
	exit 1
fi

find $BIN_DIR -name "Packages.gz" | while IFS= read -r packages_file; 
do
    package_dir=$(dirname "$packages_file")
    sig_file="$package_dir/Packages.sig"
    if [ -f "$sig_file" ]; then
	rm "$sig_file"
    fi
    FRIENDLY_NAME="${packages_file##$BIN_DIR/}"
    "$USIGN" -S -m "$packages_file" -s "$KEY" -x "$sig_file" -q -c "ff02183e3c4575ae"
    test $? -ne 0 && echo "Signing failed!" || echo "Signed $FRIENDLY_NAME"
    #VERIFY=`$USIGN -V -p "$PUB" -x "$package_dir/Packages.sig" -m "$packages_file"`
    #test $? -ne 0 && echo "Verification failed! $FRIENDLY_NAME"
    # Copy our public key into the package dir so we can easily download it if this dir is exported via webserver
    cp "$PUB" "$package_dir/key.pub"
done

PUBLIC_KEY=`cat "$PUB"`
echo
echo "Public Key:"
echo "$PUBLIC_KEY"
echo
echo "Successfully signed $PACKAGES_COUNT packages"
