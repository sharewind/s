# Copyright (c) 2014 sharewind under the WTFPL license

# INSTALL:
#   * put something like this in your .bashrc/.zshrc:
#     . /path/to/s.sh
#   * cd around for a while to build up the db
#   * PROFIT!!
#   * optionally:
#     set $_EASY_SSH_CMD in .bashrc/.zshrc to change the command (default z).
#     set $_HOST_ALIAS in .bashrc/.zshrc to change the datafile (default ~/.host_alias).
#
# USE:
#   * s web # ssh web host
#   * s 133 # ssh ip match133

case $- in
	*i*) ;;
*) echo 'ERROR: s.sh is meant to be sourced, not directly executed.'
esac

[ -d "${_HOST_ALIAS:-$HOME/.host_alias}" ] && {
echo "ERROR: s.sh's datafile (${_HOST_ALIAS:-$HOME/.host_alias}) is a directory."
}

_easy_ssh() {

	local datafile="${_HOST_ALIAS:-$HOME/.host_alias}"

	# bail out if we don't own ~/.host_alias (we're another user but our ENV is still set)
	[ -f "$datafile" -a ! -O "$datafile" ] && return

	format_hosts="$(cat "$datafile"|awk '
          function push(A,B) { A[length(A)+1] = B}
          function get(A,i){return A[i];}
          BEGIN{}
          {
              split($3,hosts,",");
              for(i in hosts){
                  if(hosts[i] != "") {
                      host_env[hosts[i]]=$1;
                      push(host_alias[hosts[i]], $2);
                  }
              }
          }
          END {
          for (host in host_env){
              printf("%-19s%-11s",host,host_env[host]);
              alias_len=length(host_alias[host]);
              for(i=1;i<=alias_len;i++){
                  printf("%-s",get(host_alias[host], i));
                  if(i<alias_len){printf("%s",", ")}
                  }
                  print "";
              }
      }'|sort)"

	# tab completion
	if [ "$1" = "--complete" ]; then
		echo "$format_hosts"|awk -v q="$2"  '
		BEGIN {
			if( q == tolower(q) ) nocase = 1
			split(substr(q,3),fnd," ")
		}
		{
			if( nocase ) {
				for( i in fnd ) tolower($0) !~ tolower(fnd[i]) && $0 = ""
			} else {
				for( i in fnd ) $0 !~ fnd[i] && $0 = ""
			}
			if( $0 ) print $0
		}
		' 2>/dev/null
		#end for completion  
	else
		# list/go
		while [ "$1" ]; 
		do case "$1" in
			--) while [ "$1" ]; do shift; local fnd="$fnd $1";done;;
			-*) local opt=${1:1}; while [ "$opt" ]; do case ${opt:0:1} in
			h) echo "${_EASY_SSH_CMD:-s} [-hl] args" >&2; return;;
			l) local list=1;;
			esac; opt=${opt:1}; done;;
			*) local fnd="$fnd $1";;
  		esac; local last=$1; shift; done


  # no file yet
  [ -f "$datafile" ] || return

  local host
  host="$(echo "$format_hosts"|awk -v list="$list" -v q="$fnd"  '
	function output(files, toopen) {
		if( list ) {
			cmd = "sort >&2"
			for( i in files ) if( files[i] ) print  files[i]| cmd
		}else{
			print toopen
	  	}
	}
	BEGIN { split(q, a, " "); }
	{
		wcase[$1] = nocase[$1] = $0
		for( i in a ) {
			if( $0 !~ a[i] ) delete wcase[$1]
			if( tolower($0) !~ tolower(a[i]) ) delete nocase[$1]
		}

		if( wcase[$1]) {
			cx = $1
			oldf = wcase[$1]
		} else if( nocase[$1]) {
			ncx = $1
			noldf = nocase[$1]
		}
	}

	END {
		if( cx ) {
			output(wcase, cx)
		} else if( ncx ){
	 		output(nocase, ncx)
 		}
	}
	')"

	  [ $? -gt 0 ] && return
	  [ "$host" ] && ssh "$host"
  fi
}

alias ${_EASY_SSH_CMD:-s}='_easy_ssh 2>&1'

if compctl &> /dev/null; then
	# zsh tab completion
	_easy_ssh_zsh_tab_completion() {
		local compl
		read -l compl
		reply=(${(f)"$(_easy_ssh --complete "$compl")"})
	}
	compctl -U -Q -K _easy_ssh_zsh_tab_completion _easy_ssh

elif complete &> /dev/null; then
	# bash tab completion
	complete -o filenames -C '_easy_ssh --complete "$COMP_LINE"' ${_EASY_SSH_CMD:-s}
fi
