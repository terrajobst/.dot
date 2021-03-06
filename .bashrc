# do nothing if not running interactively
[ -z "$PS1" ] && return

# source global /etc/bashrc and /etc/bash_completion if available
for etc in /etc /usr/local/etc; do
    for config in bashrc bash_completion; do
        [ -f $etc/$config ] && source $etc/$config
    done
done

# Set up the prompt with some defense against dumb terminals
# that don't understand the color escape sequences (e.g. M-x
# shell on the old version of emacs that ships with Mac OS X.)
__set-prompt () {
    local colors=$(tput colors 2> /dev/null)
    if [ ${colors} -ge 8 ] 2> /dev/null || [ "$TERM" == "cygwin" ]; then
        local cyan='\e[36m'
        local yellow='\e[33m'
        local plain='\e[0m'
    fi

    local ps1_dir='\n\u@\h:\w'

    if [ "$(type -t __git_ps1)" == "function" ]; then
        local ps1_git='$(__git_ps1 " (%s)")'
    fi

    local ps1_prompt='\n\$ '
    PS1="${cyan}${ps1_dir}${yellow}${ps1_git}${plain}${ps1_prompt}"
}
__set-prompt
unset -f __set-prompt

# don't include repeat commands in history 
HISTCONTROL=ignoredups:erasedups

# don't persist history
HISTFILE=

# cd to directory when given as bare command
shopt -s autocd 2> /dev/null

# expand variables in directory completion, don't escape as literal $
shopt -s direxpand 2> /dev/null

# expand recursive **/ glob patterns
shopt -s globstar 2> /dev/null

# ignore case when globbing
shopt -s nocaseglob 2> /dev/null

# aliases
alias -- -='cd -'
alias ..='cd ..'
alias cls=clear
alias cp='cp -i'
alias df='df -h'
alias dir='ls -l'
alias du='du -h'
alias h=history
alias ll='ls -l'
alias ln='ln -i'
alias ls='ls $LS_OPTIONS'
alias md=mkdir
alias mv='mv -i'
alias rd=rmdir
alias rm='rm -i'
alias ren=mv
alias tracert=traceroute
alias where='type -a'
alias which='where'
alias s='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'

# Start with BSD-safe LS_OPTIONS.
# We'll augment them if we find GNU coreutils below.
# These LSCOLORS are designed to match the GNU defaults.
export CLICOLOR=1
export LSCOLORS=exgxbxdxcxegedabagacad
LS_OPTIONS='-h -F'

# Use GNU coreutils where possible
#
# I greatly prefer GNU coreutils over the spartan BSD equivalents.
#
# On Mac OS X, install them via coreutils, which puts a g prefix in
# front of evertything by default.
#
# One way around that is to put the gnubin/ folder on the front of
# PATH, but then it's easy to take a dependency on GNU extensions in a
# script that was meant to run everywhere. Instead, the code below
# generates aliases for every coreutils command.
#
# With this setup, you can use still use a leading \ to get around the
# aliases to use the system utils.
#
# e.g.:
#
#    ls      -> runs gnu ls
#    \ls     -> runs BSD ls
#    man ls  -> shows GNU ls man page
#    \man ls -> shows BSD ls man page
#
# This escape hatch is handy during the development of scripts that
# need to be portable to BSD system without GNU coreutils.
#
__use-gnu-coreutils() {
    case $(uname) in
        GNU*|Linux|MINGW*)
            # GNU coreutils provided by the system
            return 0
            ;;
        
        Darwin)
            local coreutils=/usr/local/opt/coreutils/libexec
            if [ ! -d $coreutils ]; then
                # core utils have not been installed
                return 1
            fi

            for f in $coreutils/gnubin/*; do
                local cmd=${f##**/}
                
                if [ "$(type -t $cmd)" == "builtin" ]; then
                    # Don't try to alias built-in's like [ to g[
                    continue
                fi
	        
                local a=$(alias $cmd 2> /dev/null)
                if [ "$a" ]; then
                    # There's an existing alias, such as cp='cp -i'
                    # Munge it to cp='gcp -i'   
                    eval ${a/\'$cmd/\'g$cmd}
                else
                    alias $cmd=g$cmd
                fi
            done
            
            eval "alias man='MANPATH=$coreutils/gnuman:$MANPATH man'"
            return 0
            ;;
        
        *)
            # non-GNU, non-Mac OS system -- don't bother
            return 1
            ;;
    esac
}

if __use-gnu-coreutils; then
    LS_OPTIONS="$LS_OPTIONS --color=auto"
    if ls ~/ --group-directories-first > /dev/null 2> /dev/null; then
        LS_OPTIONS="$LS_OPTIONS --group-directories-first"
    fi
fi
unset -f __use-gnu-coreutils
