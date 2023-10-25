##########################################################
# s • Quickly list your .ssh/config connections by group #
##########################################################

# Default path to the SSH config file
source ~/cli-tools/s/s.sh
config_file="$HOME/.ssh/config"
alias s='parse_ssh_config "$config_file"'