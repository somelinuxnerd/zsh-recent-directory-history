# Fish style recent directory history

testing() {

	_debug() {
		clear
		dirh
		echo " _recent_history_prev_dirs = ${_recent_history_prev_dirs[@]}"
		echo
		echo " _recent_history_next_dirs = ${_recent_history_next_dirs[@]}"
		echo
	}

	cd ~/documents
	cd ~/downloads
	cd ~/images
	cd ~/music
	cd ~/temp
	cd ~/vbox
	cd ~/videos
	cd ~
	cd ~/.config/zsh/zshrc.d

	_debug

}


# -----------------------------------------------------------------------------
#  Global variables
# -----------------------------------------------------------------------------

typeset -ga _recent_history_prev_dirs
typeset -ga _recent_history_next_dirs
typeset -gi _recent_history_ignore_chdir=0
typeset -g _recent_history_new_pwd=""


# -----------------------------------------------------------------------------
#  Private Functions
# -----------------------------------------------------------------------------

_recent_history_at_beginning() {
	(( ${#_recent_history_prev_dirs[@]} == 0 ))
}

_recent_history_at_end() {
	(( ${#_recent_history_next_dirs[@]} == 0 ))
}

_recent_history_move_backward() {

	_recent_history_new_pwd=${_recent_history_prev_dirs[-1]}

	_recent_history_next_dirs=( "${PWD}" "${_recent_history_next_dirs[@]}" )
	_recent_history_prev_dirs=( ${_recent_history_prev_dirs[1,-2]} )

	_recent_history_ignore_chdir=1

	builtin cd "${_recent_history_new_pwd}"

}

_recent_history_move_forward() {

	_recent_history_new_pwd=${_recent_history_next_dirs[1]}

	_recent_history_prev_dirs+=( "${PWD}" )
	shift _recent_history_next_dirs

	_recent_history_ignore_chdir=1

	builtin cd "${_recent_history_new_pwd}"

}

_recent_history_on_change_directory() {

	if (( _recent_history_ignore_chdir == 1 )); then
		_recent_history_ignore_chdir=0
		return 0
	fi

	_recent_history_prev_dirs+=( "${OLDPWD}" )
	_recent_history_next_dirs=()

}


# -----------------------------------------------------------------------------
#  User Functions
# -----------------------------------------------------------------------------

dirh() {

	local dir
	local -i index

	index=${#_recent_history_prev_dirs[@]}
	for dir in ${_recent_history_prev_dirs[@]}; do
		echo " ${index}) ${dir}"
		((index--))
	done

	echo "    $(tput bold)${PWD}$(tput sgr0)"

	index=1
	for dir in ${_recent_history_next_dirs[@]}; do
		echo " ${index}) ${dir}"
		((index++))
	done

	echo

}

cdh() {
	:
}

prevd() {

	zparseopts -D -F -K -- {l,-list}=list || return 1

	if _recent_history_at_beginning; then
		(( $#list )) && dirh
		return 1
	fi

	local -i _positions=${1:-1}

	for _ in $(seq "$_positions"); do
		if _recent_history_at_beginning; then
			break
		fi
		_recent_history_move_backward
	done

	(( $#list )) && dirh

	# _debug

}

nextd() {

	zparseopts -D -F -K -- {l,-list}=list || return 1

	if _recent_history_at_end; then
		(( $#list )) && dirh
		return 1
	fi

	local -i _positions=${1:-1}

	for _ in $(seq "$_positions"); do
		if _recent_history_at_end; then
			break
		fi
		_recent_history_move_forward
	done

	(( $#list )) && dirh

	# _debug

}


# -----------------------------------------------------------------------------
#  ZLE Widgets
# -----------------------------------------------------------------------------

recent-history-prev-directory() {
	prevd
	zle reset-prompt
}

recent-history-next-directory() {
	nextd
    zle reset-prompt
}

zle -N recent-history-prev-directory
zle -N recent-history-next-directory


# -----------------------------------------------------------------------------
#  Initialize
# -----------------------------------------------------------------------------

autoload -Uz add-zsh-hook

add-zsh-hook chpwd _recent_history_on_change_directory

bindkey '^[[1;3D' recent-history-prev-directory
bindkey '^[[1;3C' recent-history-next-directory
