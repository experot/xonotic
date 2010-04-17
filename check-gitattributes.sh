#!/bin/bash

exec 3<&0

ISANYTHING=" -crlf"
ISBINARY=" -crlf -diff"
ISTEXT=" crlf=input"

LF="
"
eol=`cat .gitattributes`
find . -type f | {
	unseen=`echo "$eol" | cut -d ' ' -f 1 | grep .`
	neweol=
	while IFS= read -r LINE; do
		nam=${LINE##*/}
		case "$nam" in
			*.*)
				nam=*.${nam##*.}
				;;
		esac
		t=`file -b --mime-type "$LINE"`
		case "$t" in
			application/x-symlink)
				continue
				;;
			text/*|application/xml|application/x-ruby)
				t=true
				;;
			*)
				t=false
				;;
		esac
		unseen=`{ echo "$nam"; echo "$nam"; echo "$unseen"; } | sort | uniq -u`
		case "$LF$eol$LF$neweol$LF" in
			*$LF$nam$ISANYTHING$LF*)
				# ignore and treat as binary
				;;
			*$LF$nam$ISBINARY$LF*)
				# should be binary
				if $t; then
					echo "WARNING: file $LINE is text, should be binary"
				fi
				;;
			*$LF$nam$ISTEXT$LF*)
				# should be text
				if ! $t; then
					echo "WARNING: file $LINE is binary, should be text"
				fi
				;;
			*)
				# unknown
				if $t; then
					echo "NOTE: added new type TEXT for $LINE"
					neweol="$neweol$LF$nam$ISTEXT"
				else
					echo "NOTE: added new type BINARY for $LINE"
					neweol="$neweol$LF$nam$ISBINARY"
				fi
				;;
		esac
	done
	echo "$neweol"
	echo "not seen: $unseen"
}