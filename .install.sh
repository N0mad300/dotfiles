#!/bin/zsh

# Installing XCode CLI Tools
echo "Installing XCode CLI Tools..."
xcode-select --install

# Homebrew

## Install
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if ! grep -q 'brew shellenv' ~/.zprofile; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
fi
source ~/.zprofile

brew analytics off

## Formulae
brew install mas
brew install wget
brew install htop
brew install btop
brew install helix
brew install nushell
brew install starship
brew install fastfetch

## Casks
brew install --cask font-hack-nerd-font
brew install --cask font-sf-compact
brew install --cask font-new-york
brew install --cask font-sf-mono
brew install --cask font-sf-pro
brew install --cask alacritty
brew install --cask spotify
brew install --cask zen

# Mac App Store Apps
echo "Installing Mac App Store Apps"
mas install 497799835 # XCode

# Copying dotfiles from GitHub
[ ! -d "$HOME/dotfiles" ] && git clone --bare -b macos git@github.com:N0mad300/dotfiles.git $HOME/dotfiles
git --git-dir="$HOME/dotfiles/" --work-tree="$HOME" checkout macos
git --git-dir="$HOME/dotfiles/" --work-tree="$HOME" config --local status.showUntrackedFiles no

# Switching shell to Nushell
sudo sh -c 'echo /opt/homebrew/bin/nu >> /etc/shells'
chsh -s /opt/homebrew/bin/nu
