export VERSION_CONTROL=numbered

export LESS='-R -s -M +Gg'

export VISUAL='nvim'
export EDITOR="$VISUAL"

alias sudo=doas
alias zudo=doas

alias cp='cp --backup=existing'
alias ln='ln --backup=existing'
alias mv='mv --backup=existing'
alias install='install --backup=existing'
set VERSION_CONTROL existing

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
alias fit='git'
alias gp='git push'
alias gs='git status'
alias gh='git show'
alias gpoa='git push origin @'
alias gl='git pull'
alias ga='git add'
alias gap='git add -p'
alias g=git
alias gc='git checkout'
alias gm='git commit'
alias gma='git commit --amend'
alias gr='git log'
alias gb='git rebase --committer-date-is-author-date'
alias gbc='git rebase --continue'
alias ge='git merge'
alias gd='git diff'
alias gda='git diff @'
alias gdc='git diff --cached'
alias gds='git diff --staged'

alias grep='grep --color=auto'

alias l='eza -a -abgln -F --extended --octal-permissions --no-permissions --git'
alias lt='l -s modified'
alias t='eza -abgln -F --extended --octal-permissions --no-permissions --git -T'
alias tt='t -s modified'
alias go='grc go'

alias ip='ip -c'

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

	echo 'e: 85?'
	echo 'm: 87'
	echo 'c: 87'
	echo 'b: 96/98'
	echo 'study lolol'
	echo 'TODO'
	echo '  ka calc'
	echo '  ka sat'
	echo '  彼女と彼女の猫EF'
	echo '  yarnkey 1 trial'
end

export PAGER=vimpager

function jpeg-to-pdf
  convert -density 300 -gravity Center $argv out.pdf
end

function pdf-remove-annotations
  pdftk "$argv[1]" output - uncompress | sed '/^\/Annots/d' | pdftk - output "$argv[2]" compress
end

function gtid
  echo 903986453
end
