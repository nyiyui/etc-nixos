export VERSION_CONTROL=numbered

export LESS='-R -s -M +Gg'

export VISUAL='nvim'
export EDITOR="$VISUAL"

alias sudo=doas

alias cp='cp -b'
alias ln='ln -b'
alias mv='mv -b'
alias install='install -b'

alias f='grep -nrH -B 2 -A 2 --exclude-dir node_modules --exclude-dir venv'
alias f.='grep -nrH -B 2 -A 2 --exclude-dir node_modules --exclude-dir venv .'
alias f1='grep -nrH --exclude-dir node_modules --exclude-dir venv'
alias f0='grep -nrHo --exclude-dir node_modules --exclude-dir venv'
alias v=nvim

alias :wq='echo too much vi!'
alias :q='echo too much vi!'

# mpv aliases
alias mpvv='mpv --no-video'
alias mpvvl='mpv --no-video --loop'

# git aliases
alias gp='git push'
alias gs='git status'
alias gpoa='git push origin @'
alias gl='git pull'
alias ga='git add'
alias gap='git add -p'
alias g=git
alias gc='git checkout'
alias gm='git commit'
alias gma='git commit --amend'
alias gr='git log'
alias gb='git rebase'
alias ge='git merge'
alias gd='git diff'
alias gda='git diff @'
alias gdc='git diff --cached'
alias gds='git diff --staged'

alias grep='grep --color=auto'

alias l='exa -a -abglFn --extended --octal-permissions --no-permissions --git'
alias lt='l -s modified'
alias t='exa -abglFn --extended --octal-permissions --no-permissions --git -T'
alias tt='t -s modified'

# Fix GPG ioctl error
# https://stackoverflow.com/questions/51504367/gpg-agent-forwarding-inappropriate-ioctl-for-device
export GPG_TTY=$(tty)

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# IMEs
export QT_IM_MODULE=fcitx
export GTK_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

if status is-interactive
	fish_ssh_agent
	ssh-add -l | grep -q 'WBykfqqS1+mkkNe0XEtCzvoV3oms/Mli+bz0FhOPWzg' || ssh-add ~/inaba/geofront/id_inaba
	if ssh-add -l | grep -q 'kEasi5T4B5BiknnE7eNU0L8TtW+olomN3I9wsEdNBA4'; or ssh-add -l | grep -q 'q6lgN42+86zYYCNfTwOO/1LlgX9A97TSwD3Ph8e2Swg)'
		ssh-add ~/.ssh/id_ed25519
	end

	echo 'e: 85?'
	echo 'm: 87'
	echo 'c: 87'
	echo 'b: 96/98'
	echo 'study lolol'
end
