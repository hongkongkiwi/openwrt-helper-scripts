#!/bin/bash

USAGE="USAGE: $0 <packagename>"
SCRIPT=$(readlink -f $0)
SCRIPT_PATH=`dirname $SCRIPT`
ABSOLUTE_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SIGN_PACKAGES_SCRIPT="$SCRIPT_PATH/sign-packages.sh"

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        echo "User Aborted!"
	exit 1
}

if [ ! -f "$SIGN_PACKAGES_SCRIPT" ]; then
	echo "Cannot find sign-packages script! Aborting."
	exit 1
fi

if [[ $1 == "" ]]; then
	echo "No Package Specified"
	echo -e "$USAGE"
	exit 1
fi

if [ -f "$1" ]; then
	OFS=$IFS; IFS=$'\n'
	read -d '' -r -a PACKAGES < $1
	IFS=$OFS
else
	PACKAGES=$@
fi

for packagename in "${PACKAGES[@]}"
do
	:
	printf "Compiling ${packagename}... "
	make "package/${packagename}/"{clean,compile,install} &> /dev/null && printf "[Success]\n" || printf "[Failed!]\n"
done

printf "Regenerating Package Index... "
make "package/index" &> /dev/null && printf "[Success]\n" || printf "[Failed!]\n"
printf "Singing Packages... "
"$SIGN_PACKAGES_SCRIPT" "$ABSOLUTE_SCRIPT_PATH/bin" "$ABSOLUTE_SCRIPT_PATH/keys"  && printf "[Success]\n" || printf "[Failed!]\n"

exit 0
