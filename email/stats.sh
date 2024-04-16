#!/bin/bash

# Create a CSV export of email logs
# Log files must be uncompressed in input_dir

# Directory containing input files
input_dir="/root/mail_temp/concat"
# Output file path
output_file="/root/mail_temp/scripts/mail_log.csv"

# Function to log messages
log_message() {
    timestamp=$(date +"%Y-%m-%d %T")
    echo "[$timestamp] $1"
}

# Print table header to CSV file
printf "Message ID,UID,UID Name,Sender Email,Recipient Email,Date Sent,Status\n" > "$output_file"

# Loop through all files in the specified directory
for file in "$input_dir"/*; do
    log_message "Processing file: $file"
    # Extract message IDs, sender's UIDs, sender's emails, recipient's emails, and date sent
    ids=$(grep -oP '\b[0-9A-F]{10,}\b' "$file")
    uids=$(grep -oP "(?<=uid=)[^ ]+" "$file")
    sender_emails=$(grep -oP "(?<=from=<)[^>]+" "$file")
    recipient_emails=$(grep -oP "(?<=to=<)[^>]+" "$file")
    dates_sent=$(grep -oP "(?<=message-id=<).+(?=>)" "$file")
    statuses=$(grep -oP "(?<=status=)[^ ]+" "$file")
    # Extract the date from the filename
    file_date=$(date -r "$file" +"%Y-%m-%d")

    # Ensure all arrays have the same length
    num_ids=$(echo "$ids" | wc -l)
    num_uids=$(echo "$uids" | wc -l)
    num_senders=$(echo "$sender_emails" | wc -l)
    num_recipients=$(echo "$recipient_emails" | wc -l)
    num_dates=$(echo "$dates_sent" | wc -l)
    num_statuses=$(echo "$statuses" | wc -l)

    # Determine the minimum length among all arrays
    min_length=$(echo -e "$num_ids\n$num_uids\n$num_senders\n$num_recipients\n$num_dates\n$num_statuses" | sort -n | head -n1)

    # Loop through each entry and print the details if all fields are available
    for ((i = 1; i <= min_length; i++)); do
        id=$(echo "$ids" | sed -n "${i}p")
        uid=$(echo "$uids" | sed -n "${i}p")
        sender=$(echo "$sender_emails" | sed -n "${i}p")
        recipient=$(echo "$recipient_emails" | sed -n "${i}p")
        date=$(echo "$dates_sent" | sed -n "${i}p")
        status=$(echo "$statuses" | sed -n "${i}p")

        # Check if all fields are available
        if [[ -n "$id" && -n "$uid" && -n "$sender" && -n "$recipient" && -n "$date" && -n "$status" ]]; then
            # Get UID name from /etc/passwd
            uid_name=$(getent passwd "$uid" | cut -d: -f1)

            # Append the details to the CSV file
            printf "%s,%s,%s,%s,%s,%s,%s\n" "$id" "$uid" "$uid_name" "$sender" "$recipient" "$file_date $date" "$status" >> "$output_file"
            # Log message in the console
            log_message "Added line to CSV: $id,$uid,$uid_name,$sender,$recipient,$file_date $date,$status"
        fi
    done
    log_message "Processed file: $file"
done
