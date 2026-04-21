# Install git hooks
install-hooks:
    git config core.hooksPath .githooks

# Deploy dotfiles
apply:
    chezmoi apply
