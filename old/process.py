import sys
import pandas as pd

if len(sys.argv) != 2:
    print("Usage: python3 process.py [log_file]")
    sys.exit(1)

log_file = sys.argv[1]

sessions = []

with open(log_file, "r") as f:
    in_session = False
    for line in f:
        line = line.strip()
        if line.startswith("==== Attack ===="):
            in_session = True
            session_data = {}
            commands = []
        elif line.startswith("================"):
            session_data["List of commands used"] = f"[{', '.join(commands)}]"
            sessions.append(session_data)
            in_session = False
        elif in_session:
            if line.startswith("Date/Time connected:"):
                session_data["Date/Time attacker connected"] = line.split("Date/Time connected:")[1].strip()
            elif line.startswith("Number of commands:"):
                session_data["Number of commands used"] = int(line.split("Number of commands:")[1].strip())
            elif line.startswith("List of commands:"):
                pass  # list items handled below
            elif line.startswith("Attacker IP:"):
                session_data["IP address of attacker"] = line.split("Attacker IP:")[1].strip()
            elif line.startswith("Session duration (seconds):"):
                session_data["Time spent (in seconds)"] = float(line.split("Session duration (seconds):")[1].strip())
            else:
                # This is a command line
                commands.append(line.strip())

# Export to CSV
df = pd.DataFrame(sessions)[[
    "Date/Time attacker connected",
    "Number of commands used",
    "List of commands used",
    "IP address of attacker",
    "Time spent (in seconds)"
]]
df.to_csv("export.csv", index=False)
print("Created: export.csv")