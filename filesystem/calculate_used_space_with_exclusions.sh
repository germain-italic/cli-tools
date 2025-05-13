#!/bin/bash

# Define the directories and their corresponding filesystems to sum up
declare -A dirs=(
    ["/data/automysqlbackup/"]="/data"
    ["/data/chroot/"]="/data"
    ["/etc/letsencrypt/archive/"]="/"
    ["/root/.composer/cache/"]="/"
    ["/root/.wp-cli/cache/"]="/"
    ["/var/cache/apt/"]="/"
    ["/var/lib/"]="/"
    ["/var/log/"]="/"
)

# Initialize totals for each filesystem
declare -A total_sizes
declare -A used_spaces
declare -A adjusted_used_spaces

# Calculate the total size of the specified directories and the original used space per filesystem
for dir in "${!dirs[@]}"; do
    fs="${dirs[$dir]}"
    if [ -d "$dir" ]; then
        dir_size=$(du -sb "$dir" | awk '{print $1}')
        total_sizes[$fs]=$(( ${total_sizes[$fs]:-0} + dir_size ))
    fi
done

# Get the used space for each filesystem
for fs in "${!total_sizes[@]}"; do
    used_space=$(df --block-size=1 "$fs" | awk 'NR==2 {print $3}')
    used_spaces[$fs]=$used_space
    adjusted_used_spaces[$fs]=$((used_space - ${total_sizes[$fs]}))
done

# Function to convert sizes to human-readable format
format_size() {
    num=$1
    if [ "$num" -lt 1024 ]; then
        echo "${num}B"
    elif [ "$num" -lt $((1024 * 1024)) ]; then
        echo "$((num / 1024))K"
    elif [ "$num" -lt $((1024 * 1024 * 1024)) ]; then
        echo "$((num / 1024 / 1024))M"
    else
        echo "$((num / 1024 / 1024 / 1024))G"
    fi
}

# Output the results for each filesystem
for fs in "${!total_sizes[@]}"; do
    echo "Filesystem: $fs"
    echo "  Total size of specified directories: $(format_size "${total_sizes[$fs]}")"
    echo "  Original used space according to df -h: $(format_size "${used_spaces[$fs]}")"
    echo "  Adjusted used space (after subtracting directories): $(format_size "${adjusted_used_spaces[$fs]}")"
done
