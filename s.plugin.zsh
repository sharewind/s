_load_s() {
  source $1/s.sh
}

[[ -f $ZSH_CUSTOM/plugins/s/s.plugin.zsh ]] && _load_s $ZSH_CUSTOM/plugins/s
[[ -f $ZSH/plugins/s/s.plugin.zsh ]] && _load_s $ZSH/plugins/s
