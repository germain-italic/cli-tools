#!/bin/bash

# Function to parse the SSH config file and extract groups and hosts
parse_ssh_config() {
  local config_file="$1"
  local group_names=()
  declare -A hosts

  # Read the SSH config file and populate group_names and hosts arrays
  while read -r line; do
    if [[ $line =~ ^#\ Group\ (.+) ]]; then
      current_group="${BASH_REMATCH[1]}"
      group_names+=("$current_group")
    elif [[ $line =~ ^Host\ ([^*].*) ]]; then
      hosts["$current_group"]+=" ${BASH_REMATCH[1]}"
    fi
  done < "$config_file"

  local selected_group=""

  # Allow users to select a group or return to group selection
  echo "Select a group of connections (number):"
  while true; do
    if [ -z "$selected_group" ]; then
      select group_name in "${group_names[@]}" "Exit"; do
        case $group_name in
          "Exit")
            echo "Goodbye!"
            exit 0
            ;;
          *)
            selected_group="$group_name"
            echo "Selected group: $selected_group"
            break
            ;;
        esac
      done
    else
      select_host "$selected_group"
      selected_group=""
    fi
  done
}

# Function to display and select a host within a group
select_host() {
  local selected_group="$1"
  echo "Now select a host to connect to:"

  # Display hosts within the selected group
  local hosts_list="${hosts[$selected_group]}"
  IFS=' ' read -ra host_array <<< "$hosts_list"
  for i in "${!host_array[@]}"; do
    echo "$(($i + 1))) ${host_array[$i]}"
  done

  # Prompt the user to select a host or return to group selection
  while true; do
    read -p "Select a host (number) or type '-' to return to groups: " input

    if [[ "$input" == "-" || "$input" == "leftarrow" ]]; then
      return  # Return to group selection
    elif [[ "$input" =~ ^[0-9]+$ ]] && ((input >= 1 && input <= ${#host_array[@]})); then
      selected_host="${host_array[$input - 1]}"
      echo "You selected host: $selected_host - connecting..."
      ssh "$selected_host"
      return
    else
      echo "Invalid selection."
    fi
  done
}

# Default path to the SSH config file
# config_file="ssh-config.sample"
config_file="$HOME/.ssh/config"