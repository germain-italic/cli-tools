#!/bin/bash

# Function to parse the SSH config file and extract groups
parse_ssh_config() {
  local config_file="$1"
  local groups=()

  while IFS= read -r line; do
    if [[ "$line" =~ ^\#\ Group\ (.+) ]]; then
      groups+=("${BASH_REMATCH[1]}")
    fi
  done < "$config_file"

  # Sort the groups alphabetically
  sorted_groups=($(printf "%s\n" "${groups[@]}" | sort))
  echo "${sorted_groups[@]}"
}

# Default path to the SSH config file
config_file="$HOME/.ssh/config"

# Call the function to parse the SSH config file and display groups
parsed_groups=($(parse_ssh_config "$config_file"))

# Display the sorted groups
echo "List of groups:"
for group in "${parsed_groups[@]}"; do
  echo "$group"
done
