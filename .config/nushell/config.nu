# config.nu
#
# Installed by:
# version = "0.106.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

$env.config.show_banner = false
$env.config.buffer_editor = "hx"

# homebrew
$env.HOMEBREW_PREFIX = "/opt/homebrew"
$env.HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
$env.HOMEBREW_REPOSITORY = "/opt/homebrew"
$env.PATH ++= ['/opt/homebrew/bin', '/opt/homebrew/sbin']

# starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# dotfiles management
# 
# Usefull commands :
# To track a new file:     dotfiles add <path to file to track>
# To update tracked files: dotfiles add "-u"
# To commit :              dotfiles commit "-m" "<message>"
# To push :                dotfiles push origin macos
#
# Note : Don't forget flags (ex: -m/--help) need to be in quote
def dotfiles [...args: string] {
    git $"--git-dir=($env.HOME)/dotfiles" $"--work-tree=($env.HOME)" ...$args
}
