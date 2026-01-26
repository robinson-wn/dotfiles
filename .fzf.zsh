# Setup fzf
# ---------
if [[ ! "$PATH" == */home/wnr/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/wnr/.fzf/bin"
fi

source <(fzf --zsh)
