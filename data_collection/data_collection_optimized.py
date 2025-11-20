#!/usr/bin/env python3
"""
data_collection_optimized.py - High-performance JSON to CSV converter
Converts all JSON log files to a single CSV file with parallel processing
Usage: python3 data_collection_optimized.py [output_file]
Default output: /home/aces/HACS200_Honeypot/logs/honeypot_data.csv
"""

import os
import sys
import json
import csv
import re
from datetime import datetime
from pathlib import Path
from multiprocessing import Pool, cpu_count
from typing import List, Dict, Tuple, Optional
import traceback


# Configuration
DEFAULT_OUTPUT = "/home/aces/HACS200_Honeypot/logs/honeypot_data.csv"
LOGS_DIR = "/home/aces/HACS200_Honeypot/logs"
VALIDATION_LOG = "data_collection/data_validation_errors.log"

# Statistics counters (will be aggregated from workers)
stats = {
    'total_files': 0,
    'processed_files': 0,
    'total_entries': 0,
    'failed_entries': 0,
    'commands_split': 0,
    'duration_errors': 0,
    'num_commands_fixed': 0
}


def extract_timestamp(line: str) -> Optional[str]:
    """Extract timestamp from log line (returns: 'YYYY-MM-DD HH:MM:SS.MS')"""
    parts = line.split()
    if len(parts) >= 2:
        return f"{parts[0]} {parts[1]}"
    return None


def timestamp_to_ms(timestamp: str) -> Optional[int]:
    """Convert timestamp to milliseconds since epoch"""
    try:
        # Split into date, time, and milliseconds
        date_part, time_with_ms = timestamp.split()
        time_part, ms_part = time_with_ms.split('.')
        
        # Parse datetime
        dt = datetime.strptime(f"{date_part} {time_part}", "%Y-%m-%d %H:%M:%S")
        
        # Convert to milliseconds
        total_ms = int(dt.timestamp() * 1000) + int(ms_part)
        return total_ms
    except (ValueError, AttributeError):
        return None


def calculate_mitm_time(out_file: str) -> int:
    """Calculate time from attacker connection to last command"""
    if not os.path.exists(out_file):
        return 0
    
    try:
        with open(out_file, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Find connection timestamp
        connection_match = re.search(r'^.*Attacker connected:.*$', content, re.MULTILINE)
        if not connection_match:
            return 0
        
        connect_timestamp = extract_timestamp(connection_match.group(0))
        if not connect_timestamp:
            return 0
        
        connect_ms = timestamp_to_ms(connect_timestamp)
        if connect_ms is None:
            return 0
        
        # Find last command timestamp
        command_lines = re.findall(
            r'^.*(line from reader:|Noninteractive mode attacker command:).*$',
            content,
            re.MULTILINE
        )
        
        if not command_lines:
            return 0
        
        last_cmd_timestamp = extract_timestamp(command_lines[-1])
        if not last_cmd_timestamp:
            return 0
        
        last_cmd_ms = timestamp_to_ms(last_cmd_timestamp)
        if last_cmd_ms is None:
            return 0
        
        return max(0, last_cmd_ms - connect_ms)
    
    except Exception:
        return 0


def fix_json_content(content: str) -> str:
    """Fix common JSON malformations"""
    # Fix 1: Remove trailing commas before closing brackets/braces
    content = re.sub(r',(\s*[\]}])', r'\1', content)
    
    # Fix 2: Quote unquoted strings in commands array
    def fix_commands_line(line):
        if '"commands":' not in line:
            return line
        
        match = re.search(r'"commands":\s*\[([^\]]*)\]', line)
        if not match:
            return line
        
        array_content = match.group(1).strip()
        
        if not array_content:
            return re.sub(r'"commands":\s*\[\s*\],?', '"commands": [],', line)
        
        if array_content.endswith(','):
            array_content = array_content[:-1].strip()
        
        # Split by comma and quote each unquoted element
        commands = []
        current = ""
        in_quotes = False
        quote_char = None
        
        for char in array_content:
            if char in ('"', "'") and (not in_quotes or char == quote_char):
                in_quotes = not in_quotes
                quote_char = char if in_quotes else None
                current += char
            elif char == ',' and not in_quotes:
                if current.strip():
                    cmd = current.strip().rstrip(',')
                    if cmd.startswith('"') and cmd.endswith('"') and len(cmd) > 2:
                        cmd = cmd[1:-1]
                        cmd = cmd.replace('\\"', 'QUOTE_PLACEHOLDER')
                        cmd = cmd.replace('\\', '\\\\')
                        cmd = cmd.replace('QUOTE_PLACEHOLDER', '\\"')
                        cmd = '"' + cmd + '"'
                    elif not (cmd.startswith('"') and cmd.endswith('"')):
                        cmd = cmd.replace('\\', '\\\\').replace('"', '\\"')
                        cmd = '"' + cmd + '"'
                    commands.append(cmd)
                current = ""
            else:
                current += char
        
        if current.strip():
            cmd = current.strip().rstrip(',')
            if cmd.startswith('"') and cmd.endswith('"') and len(cmd) > 2:
                cmd = cmd[1:-1]
                cmd = cmd.replace('\\"', 'QUOTE_PLACEHOLDER')
                cmd = cmd.replace('\\', '\\\\')
                cmd = cmd.replace('QUOTE_PLACEHOLDER', '\\"')
                cmd = '"' + cmd + '"'
            elif not (cmd.startswith('"') and cmd.endswith('"')):
                cmd = cmd.replace('\\', '\\\\').replace('"', '\\"')
                cmd = '"' + cmd + '"'
            commands.append(cmd)
        
        if commands:
            fixed_line = re.sub(
                r'"commands":\s*\[[^\]]*\]',
                '"commands": [' + ', '.join(commands) + ']',
                line
            )
        else:
            fixed_line = re.sub(r'"commands":\s*\[[^\]]*\]', '"commands": []', line)
        
        return fixed_line
    
    lines = content.split('\n')
    fixed_lines = [fix_commands_line(line) for line in lines]
    return '\n'.join(fixed_lines)


def split_commands_by_semicolons(commands: List[str]) -> List[str]:
    """Split commands by semicolons and flatten"""
    new_commands = []
    for cmd in commands:
        if isinstance(cmd, str) and ';' in cmd:
            parts = [part.strip() for part in cmd.split(';')]
            parts = [p for p in parts if p]
            new_commands.extend(parts)
        else:
            new_commands.append(cmd)
    return new_commands


def process_single_file(log_file: str) -> Tuple[List[Dict], Dict]:
    """Process a single log file and return CSV rows and stats"""
    rows = []
    file_stats = {
        'entries': 0,
        'failed': 0,
        'commands_split': 0,
        'duration_errors': 0,
        'num_commands_fixed': 0
    }
    
    try:
        # Calculate MITM time from .out file
        out_file = log_file.replace('.log', '.out')
        mitm_time = calculate_mitm_time(out_file)
        
        # Read and fix JSON content
        with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        if not content.strip():
            return rows, file_stats
        
        # Fix JSON malformations
        fixed_content = fix_json_content(content)
        
        # Parse JSON (handle both array and single object)
        try:
            data = json.loads(fixed_content)
            if not isinstance(data, list):
                data = [data]
        except json.JSONDecodeError:
            # Try parsing line by line for newline-delimited JSON
            data = []
            for line in fixed_content.split('\n'):
                line = line.strip()
                if line:
                    try:
                        data.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
        
        if not data:
            file_stats['failed'] = 1
            return rows, file_stats
        
        # Process each entry
        for entry in data:
            try:
                # Get commands
                commands = entry.get('commands', [])
                original_num_commands = entry.get('num_commands', 0)
                
                # Split commands by semicolons
                old_cmd_count = len(commands)
                commands = split_commands_by_semicolons(commands)
                if len(commands) != old_cmd_count:
                    file_stats['commands_split'] += 1
                
                # Update num_commands to match array length
                actual_num_commands = len(commands)
                if actual_num_commands != original_num_commands:
                    file_stats['num_commands_fixed'] += 1
                
                # Validate duration
                duration_ms = entry.get('duration_ms') or entry.get('duration', 0)
                try:
                    duration_ms = int(duration_ms)
                except (ValueError, TypeError):
                    duration_ms = 0
                
                if duration_ms < 0 or duration_ms > 600000:
                    file_stats['duration_errors'] += 1
                    # Log to validation file
                    with open(VALIDATION_LOG, 'a', encoding='utf-8') as log_f:
                        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        log_entry = (
                            f"[{timestamp}] INVALID DURATION: {duration_ms}ms | "
                            f"File: {log_file} | "
                            f"Honeypot: {entry.get('honeypot_name', 'N/A')} | "
                            f"IP: {entry.get('attacker_ip', 'N/A')}\n"
                        )
                        log_f.write(log_entry)
                
                # Build CSV row
                row = {
                    'timestamp': entry.get('timestamp', ''),
                    'honeypot_name': entry.get('honeypot_name', ''),
                    'attacker_ip': entry.get('attacker_ip', ''),
                    'public_ip': entry.get('public_ip', ''),
                    'language': entry.get('language', ''),
                    'login': entry.get('login', ''),
                    'connect_time': entry.get('connect_time', ''),
                    'disconnect_time': entry.get('disconnect_time', ''),
                    'duration_ms': str(duration_ms),
                    'num_commands': str(actual_num_commands),
                    'commands': json.dumps(commands),
                    'avg_time_between_commands': entry.get('avg_time_between_commands', ''),
                    'is_bot': str(entry.get('is_bot', '')).lower(),
                    'is_noninteractive': str(entry.get('is_noninteractive', '')).lower(),
                    'disconnect_reason': entry.get('disconnect_reason', ''),
                    'time_to_last_command_ms': str(mitm_time)
                }
                
                rows.append(row)
                file_stats['entries'] += 1
                
            except Exception as e:
                file_stats['failed'] += 1
                continue
    
    except Exception as e:
        file_stats['failed'] = 1
        print(f"[WARNING] Error processing {log_file}: {str(e)}")
    
    return rows, file_stats


def process_file_wrapper(args):
    """Wrapper for multiprocessing with progress tracking"""
    log_file, file_num, total_files = args
    filename = os.path.basename(log_file)
    
    # Process the file
    rows, file_stats = process_single_file(log_file)
    
    # Return results with file info for progress display
    return {
        'filename': filename,
        'file_num': file_num,
        'total_files': total_files,
        'rows': rows,
        'stats': file_stats
    }


def main():
    """Main execution function"""
    print("[*] Ahoy! Honeypot JSON to CSV Converter - Optimized Edition")
    print("[*] ============================================================")
    
    # Get output file from args or use default
    output_file = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUTPUT
    
    print(f"[*] Scanning for .log files in {LOGS_DIR}")
    
    # Find all .log files
    log_files = []
    for root, dirs, files in os.walk(LOGS_DIR):
        for file in files:
            if file.endswith('.log'):
                log_files.append(os.path.join(root, file))
    
    if not log_files:
        print(f"[*] No .log files found in {LOGS_DIR}")
        return 0
    
    stats['total_files'] = len(log_files)
    print(f"[*] Found {stats['total_files']} log file(s)")
    print(f"[*] Output file: {output_file}")
    print(f"[*] Using {min(cpu_count(), 8)} worker processes for parallel processing")
    print("")
    print("[*] Processing log files...")
    
    # Clear validation log at start
    if os.path.exists(VALIDATION_LOG):
        os.remove(VALIDATION_LOG)
    
    # Prepare arguments for parallel processing
    process_args = [(log_file, i+1, len(log_files)) for i, log_file in enumerate(log_files)]
    
    # Process files in parallel
    all_rows = []
    num_workers = min(cpu_count(), 8)  # Cap at 8 workers
    
    with Pool(processes=num_workers) as pool:
        results = pool.map(process_file_wrapper, process_args)
    
    # Aggregate results
    for result in results:
        print(f"[*] [{result['file_num']}/{result['total_files']}] Processed: {result['filename']}")
        print(f"    → Converted {result['stats']['entries']} entries")
        if result['stats']['commands_split'] > 0:
            print(f"    → Split {result['stats']['commands_split']} commands by semicolons")
        
        all_rows.extend(result['rows'])
        stats['processed_files'] += 1
        stats['total_entries'] += result['stats']['entries']
        stats['failed_entries'] += result['stats']['failed']
        stats['commands_split'] += result['stats']['commands_split']
        stats['duration_errors'] += result['stats']['duration_errors']
        stats['num_commands_fixed'] += result['stats']['num_commands_fixed']
    
    # Write CSV
    print("")
    print("[*] Writing CSV file...")
    
    fieldnames = [
        'timestamp', 'honeypot_name', 'attacker_ip', 'public_ip', 'language',
        'login', 'connect_time', 'disconnect_time', 'duration_ms', 'num_commands',
        'commands', 'avg_time_between_commands', 'is_bot', 'is_noninteractive',
        'disconnect_reason', 'time_to_last_command_ms'
    ]
    
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_rows)
    
    # Print final statistics
    print("")
    print("[*] ============================================================")
    print("[*] Conversion Complete!")
    print("[*] ============================================================")
    print(f"[*] Files processed: {stats['processed_files']}")
    print(f"[*] Entries converted: {stats['total_entries']}")
    print(f"[*] Failed entries: {stats['failed_entries']}")
    print("")
    print("[*] Validation Results:")
    print(f"    → Commands split by semicolons: {stats['commands_split']}")
    print(f"    → Duration errors found: {stats['duration_errors']}")
    print(f"    → num_commands mismatches fixed: {stats['num_commands_fixed']}")
    if stats['duration_errors'] > 0:
        print(f"    → Duration errors logged to: {VALIDATION_LOG}")
    print("")
    print(f"[*] Output saved to: {output_file}")
    print("")
    
    # Exit with error if critical failure
    if stats['total_entries'] == 0 and stats['failed_entries'] > 0:
        print("[ERROR] No entries were successfully converted!")
        return 1
    
    return 0


if __name__ == '__main__':
    sys.exit(main())

