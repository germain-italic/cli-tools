#!/bin/bash

# Function to parse the SSH config file and extract groups and hosts
parse_ssh_config() {
  local config_file="$1"
  local group_names=("Connections without group") # Initialize default group for orphan hosts
  declare -A hosts

  # The default path to the SSH config file is defined in ../tools.sh
  # You can also call the script directly with the path as argument:
  # bash s/s.sh s/ssh-config.sample
  # bash s/s.sh $HOME/.ssh/config
  # (this is useful when debugging the script)

  # Check if the parth argument is passed
  if [ -n "$1" ]; then
    config_file="$1"
  fi

  # Check if the config file exists
  if [ ! -f "$config_file" ]; then
    echo "Config file not found: $config_file"
  fi

  # Read the SSH config file and populate group_names and hosts arrays
  while read -r line; do
    # echo "Line: $line"
    if [[ $line =~ ^#\ Group\ (.+) ]]; then
      current_group="${BASH_REMATCH[1]}"
      group_names+=("$current_group")
    elif [[ $line =~ ^Host\ ([^*].*) ]]; then
      if [ -n "$current_group" ]; then
        hosts["$current_group"]+=" ${BASH_REMATCH[1]}"
      else
        hosts["Connections without group"]+=" ${BASH_REMATCH[1]}"
      fi
    fi
  done <"$config_file"

  local selected_group=""

  # Allow users to select a group or return to group selection
  echo "Select a group of connections (number):"
  while true; do
    if [ -z "$selected_group" ]; then
      select group_name in "${group_names[@]}" "Exit"; do
        case $group_name in
        "Exit")
          echo "Goodbye!"
          return 1
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

  # Display hosts within the selected group or all hosts
  local hosts_list="${hosts["$selected_group"]}"
  IFS=' ' read -ra host_array <<<"$hosts_list"
  for i in "${!host_array[@]}"; do
    echo "$(($i + 1))) ${host_array[$i]}"
  done

  # Prompt the user to select a host or return to group selection
  while true; do
    read -p "Select a host (number) or type '-' to return to groups: " input

    if [[ "$input" == "-" || "$input" == "leftarrow" ]]; then
      return # Return to group selection
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
