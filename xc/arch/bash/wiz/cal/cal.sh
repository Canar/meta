#!/bin/bash
epoch-time(){
	date '+%s'
}
pause(){
	echo "Please press enter to continue."
	read -e temp
}
handle(){
	$1
	if [[ $? -ne 0 ]] ; then
		$2
	fi
	$3
	
}
dont-clobber(){
	if [[ -f "$1" ]] ; then
		if [[ ! -f "$1.$now" ]] ; then 
			cp "$1" "$1.$now"
		fi
		#rm "$1"
	fi
}
process-param-from-var-into-file-via-stdio(){ #executes $1, passing the value in $2 to stdin, and saving stdout to file $3
	dont-clobber "$3"
	( $1 <<< "$2" ) > "$3"
}
process(){ #unwraps process to execute from quotes, and executes it. permits all other variables to be quoted without loss of generality
	process="$1"
	shift
	$process "$@"
}
process-file-inplace(){
	dont-clobber "$2"
	process "$@"
}
write-param-to-file(){
	dont-clobber "$2"
	process-stdio cat "$1" > "$2"
}
entity-encode(){
	recode UTF-8..XML "$1"
}
entity-decode(){
	recode XML..UTF-8 "$1"
}
read-line-into-file-via-stdio(){ #file is $1
	read -r -e temp
	dont-clobber "$1"
	( echo "$temp" ) > "$1" 
}
read-line-into-file() {
	IFS=$nl
	read-line-into-file-via-stdio "$1"
	unset IFS
}
remove-newlines-from-file(){
	process-file-inplace "tr -d '\n'" "$1"
}
split-file-on-html-tag-to-file(){
	dont-clobber "$3"
	sed -r 's (<'"$2"'>)(.*)(</'"$2"'>) \n\1\2\3\n g' "$1"  > "$3"
}
shift-lines-into-files(){
	if [[ -n "$1" ]] ; then
		read-line-into-file "$1"
		shift
		shift-lines-into-files "$@"
	fi	
}
shift-lines-from-file-into-files(){
	f="$1"
	shift
	shift-lines-into-files "$@" < "$f"
}
log-params(){
	ept=`epoch-time`
	eval 'echo "[ @ $ept ] $@"' >> log
	"$@"
}
log(){
	log-params "$@"
}
epoch-time(){
	date '+%s'
}
insert-param-after-param-in-file-to-file(){
	sed -r 's/('"$2"')/\1'"$1"'/g' "$3" > "$4"
}
split-first-line-of-file-to-file(){
	dont-clobber "$2"
	dont-clobber "$1"
	dont-clobber "$3"
	head -1 <"$1" >"$2"
	if [[ -n "$3" ]] ; then
		tail -n +2 "$1" >"$3"
	fi
}
split-file-after-param-to-file-and-file(){
	tmp="$1.tmp"
	insert-param-after-param-in-file-to-file "\n" "$2" "$1" "$tmp"
	split-first-line-of-file-to-file "$tmp" "$3" "$4"
#	rm -f "$tmp"
}
nl='
'
now=`epoch-time`
set -e
cd run
log read-line-into-file out
log split-file-after-param-to-file-and-file out '>' top encoded
log entity-decode encoded
less encoded
log split-file-on-html-tag-to-file encoded Query out.split
log shift-lines-from-file-into-files out.split head body tail
entity-encode head
entity-encode tail
if [[ $1 == "" ]] ; then
	recode HTML..UTF-8 body 
	xmllint --format body --output b2
	vi  b2
	xmllint --noblanks b2 --output body
	tail -n +2 body > b2
	recode UTF-8..HTML b2
	echo "Saving current session as [part].$now."
	( set -x
	cp head head.$now
	cp b2 body.$now
	cp tail tail.$now )
else
	echo "Reusing body from $1."
	cp $1 b2
fi
( 
	echo '
Original line:
' 
	cat out
	echo '
Copy from below...
' 
	echo '' 
	( 	(  
			cat top
			cat head 
			cat b2
			cat tail 
		) | tr -d '\n' ) 
	echo "" 
) 
cd ..
