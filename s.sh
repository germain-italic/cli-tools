#!/bin/bash

# Function to parse the SSH config file and extract groups and hosts
parse_ssh_config() {
  local config_file="$1"

  awk -v IGNORE_HOST="Host *" '
    /^# Group (.+)/ {
      if (in_group) {
        print_group()
      }
      in_group = 1
      group_name = substr($0, 9)
      next
    }

    /^Host (.+)/ {
      if (in_group && $0 != IGNORE_HOST) {
        hosts[group_name] = hosts[group_name] " " $2
      }
    }

    END {
      if (in_group) {
        print_group()
      }
    }

    function print_group() {
      print "[" group_name "]"
      split(hosts[group_name], host_array)
      n = asort(host_array)
      for (i = 1; i <= n; i++) {
        print "  Host: " host_array[i]
      }
      delete hosts[group_name]
      in_group = 0
    }
  ' "$config_file"
}

# Default path to the SSH config file
config_file="ssh-config.sample"

# Call the function to parse the SSH config file and display groups and hosts
parse_ssh_config "$config_file"
