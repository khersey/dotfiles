#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Check and set default shell to bash if it's not already
current_shell=$(echo $SHELL)
if [[ "$current_shell" != "/bin/bash" ]]; then
    echo "Changing default shell to bash..."
    chsh -s /bin/bash
fi

# Add source command to .bash_profile if it doesn't exist
BASH_DARWIN_SOURCE="source $SCRIPT_DIR/.bash_darwin"
if ! grep -q "$BASH_DARWIN_SOURCE" ~/.bash_profile 2>/dev/null; then
    echo "Adding .bash_darwin to .bash_profile..."
    echo "$BASH_DARWIN_SOURCE" >> ~/.bash_profile
fi

# Apply git aliases
echo "Applying git aliases..."
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        eval "$line"
    fi
done < "$DOTFILES_DIR/git-aliases"

echo "Setup complete! Please restart your terminal or run 'source ~/.bash_profile' to apply changes." 