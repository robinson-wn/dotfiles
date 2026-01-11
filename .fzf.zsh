# Setup fzf
# ---------
if [[ ! "$PATH" == *"$HOME/.fzf/bin"* ]]; then
  PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Initialize fzf for zsh
# Only run if fzf is found to prevent shell startup errors
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi