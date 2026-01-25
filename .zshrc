# --- Helper Function for Clean Sourcing ---
# This avoids repetitive [[ -f ]] checks and keeps the file readable
function source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

# --- Module Loading ---
# Using the helper for your custom zsh files
source_if_exists "$HOME/.zsh/aliases.zsh"
source_if_exists "$HOME/.zsh/functions.zsh"
source_if_exists "$HOME/.zsh/starship.zsh"
source_if_exists "$HOME/.zsh/nvm.zsh"
source_if_exists "$HOME/.zsh/wsl2fix.zsh"
source_if_exists "$HOME/.secrets"

# --- Homebrew Setup ---
# Hardcoded paths can fail if you move to a different Linux distro or Mac.
# This check ensures brew is only initialized if the binary exists.
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# --- Tool Initializations ---
# Wrap evals in 'command -v' checks to prevent "command not found" errors
# if a tool is temporarily uninstalled or the PATH changes.
# Check for starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Check for direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# Check for zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# --- History & FZF ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=20000
# Best practice: ensure the history file exists
touch "$HISTFILE" 2>/dev/null

source_if_exists "$HOME/.fzf.zsh"

# --- Conda Initialization ---
# (Kept mostly as-is since it's auto-generated, but added a check for the dir)
if [[ -d "$HOME/miniconda3" ]]; then
    __conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
            . "$HOME/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="$HOME/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
fi

# --- Python & Spark ---
# We check if $PYTHON_INTERP is set before trying to activate
export PYTHONPATH=.
if [[ -n "$PYTHON_INTERP" ]]; then
    conda activate "$PYTHON_INTERP" 2>/dev/null
fi

# Use 'command -v' instead of 'which' for better POSIX compliance/speed
if (( $+commands[python] )); then
    export PYSPARK_PYTHON=$(command -v python)
    export PYSPARK_DRIVER_PYTHON=$(command -v python)
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
