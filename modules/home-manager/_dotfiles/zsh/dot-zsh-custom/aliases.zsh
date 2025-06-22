# aliases 

NEOVIM_CONFIG_DIR="$HOME/.config/nvim/"
export EDITOR="nvim"

alias ":r"="source ~/.zshrc"
alias cd="z"
alias cls="clear"
alias ezs="$EDITOR ~/.zshrc"
alias find="fd"
alias kc="minikube kubectl --"
alias kcaf="minikube kubectl -- apply -f"
alias kp=kill_port
alias kubectl="minikube kubectl --"
alias kubectl="minikube kubectl --"
alias l="eza"
alias la="eza -a"
alias lah="eza -lah"
alias ld="lazydocker"
alias lg="lazygit"
alias ll="eza -l"
alias ls="eza"
alias ncfg="cd ~/.config/nvim/lua/user && nvim . && cd -"
alias ollamas="export OLLAMA_ORIGINS='*' && ollama serve"
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
alias serve='miniserve'
alias szs="source ~/.zshrc"
alias v="nvim"
alias vcfg="$EDITOR $NEOVIM_CONFIG_DIR"
alias venv=setup_venv
alias vv="nvim ."
alias gifzf=gitignore_fzf_execute
alias zcfg="$EDITOR $HOME/.zshrc"
alias lvim="NVIM_APPNAME='nvim-lazy' nvim"
alias htop="glances"
