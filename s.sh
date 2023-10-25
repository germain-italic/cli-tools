#!/bin/bash

# Function to parse the SSH config file and extract groups and hosts
parse_ssh_config() {
  local config_file="$1"

  awk '
    BEGIN {
      group = ""
    }

    /^# Group (.+)/ {
      if (group != "") {
        groups[group] = hosts
        hosts = ""
      }
      group = $3
    }

    /^Host (.+)/ {
      if (hosts == "") {
        hosts = $2
      } else {
        hosts = hosts ", " $2
      }
    }

    END {
      if (group != "") {
        groups[group] = hosts
      }
      for (group in groups) {
        print "[" group "]"
        split(groups[group], hosts_array, ", ")
        asort(hosts_array)
        for (i = 1; i <= length(hosts_array); i++) {
          print "  Host: " hosts_array[i]
        }
      }
    }
  ' "$config_file"
}

# Default path to the SSH config file
config_file="$HOME/.ssh/config"

# Call the function to parse the SSH config file and display groups and hosts
parse_ssh_config "$config_file"
