# 0 0 * * * cd <absolute path of /HACS200_Honeypot> && ./data_collection/log_health.sh

#!/bin/bash
# System Health Monitoring Script

# Create logs directory for health metrics
health_logs_dir="logs/system_health"
mkdir -p "$health_logs_dir"

# Timestamp for the log entry
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
log_file="$health_logs_dir/health_log_$(date +"%Y%m%d").txt"

# Collect metrics
echo "=== System Health Check - $timestamp ===" >> "$log_file"

# 1. Available RAM
echo "--- Memory Usage ---" >> "$log_file"
free -h >> "$log_file"

# 2. Available Disk Space
echo -e "\n--- Disk Space ---" >> "$log_file"
df -h >> "$log_file"

# 3. Average System Load
echo -e "\n--- System Load ---" >> "$log_file"
uptime >> "$log_file"

# 4. Network Traffic Since Reboot
echo -e "\n--- Network Traffic ---" >> "$log_file"
cat /proc/net/dev >> "$log_file"

echo -e "\n========================================\n" >> "$log_file"
