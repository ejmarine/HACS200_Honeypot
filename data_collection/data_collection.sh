#!/bin/bash

# Set the base logs directory and Ext2 directory
logs_dir="logs"
ext2_dir="Ext2"
zip_dir="data_zips"
timestamp=$(date +"%Y%m%d_%H%M%S")
zip_filename="logs_backup_$timestamp.zip"

# Create the data_zips directory if it doesn't exist
mkdir -p "$zip_dir"

# Create a zip file from all the logs in the specified subdirectories, including Ext2 if it exists
create_zip() {
    echo "Creating a zip file of all logs and Ext2 if present..."

    # Navigate to the logs directory
    cd "$logs_dir" || { echo "Failed to navigate to $logs_dir"; exit 1; }

    # Include Ext2 if it exists
    if [ -d "../$ext2_dir" ]; then
        zip -r "../$zip_filename" authentication_attempts/ keystrokes/ logins/ logouts/ session_streams/ "../$ext2_dir"
    else
        zip -r "../$zip_filename" authentication_attempts/ keystrokes/ logins/ logouts/ session_streams/
    fi

    # Check if the zip command succeeded
    if [ $? -eq 0 ]; then
        echo "Zip file created successfully: $zip_filename"
    else
        echo "Failed to create the zip file."
        exit 1
    fi

    # Navigate back to the original directory
    cd ..

    # Move the zip file to the data_zips directory
    mv "$zip_filename" "$zip_dir/"
    echo "Zip file moved to $zip_dir/$zip_filename"
}

# Delete all files inside the subdirectories
clean_directories() {
    echo "Deleting all files inside the subdirectories..."

    # Delete all files in the specified subdirectories
    rm -rf "$logs_dir"/authentication_attempts/* \
           "$logs_dir"/keystrokes/* \
           "$logs_dir"/logins/* \
           "$logs_dir"/logouts/* \
           "$logs_dir"/session_streams/*

    echo "All files inside the subdirectories have been deleted."
}

# Main function
main() {
    # Create the zip file
    create_zip

    # Clean up by deleting all files in the subdirectories
    clean_directories
}

# Run the main function
main
