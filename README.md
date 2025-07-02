# Linux_System_Monitoring_Tool

Linux System Monitoring and Host Intrusion Detection!

🛡 SysMonitor Toolkit - User Guide & Short Report
Version: 1.0 Last Updated: June 21, 2025

📘 Overview
SysMonitor is a Bash-based system monitoring and auditing toolkit for Linux. It simulates basic Host Intrusion Detection System (HIDS) behavior using native tools and sends alerts via Discord and email. It logs system performance data in a Chrome/Perfetto-compatible JSON trace file and supports automated, periodic monitoring via cron.

✅ Key Features
Monitors CPU, memory, and disk usage with customizable thresholds.

Tracks top memory-consuming processes and active network connections.

Audits:

Currently logged-in users
Recent login history
Recent shell commands from .bash_history / .zsh_history
Detects brute-force attacks from failed SSH login attempts.

Reports system uptime.

Sends alerts through:

📧 Email
🔔 Discord Webhook
Logs usage metrics to a JSON trace file ($HOME/sysmonitor_trace.json) for Chrome Tracing / Perfetto.

Displays ASCII progress bars for visual feedback.

⚙ Prerequisites
Linux system with Bash

Required tools: awk, bc, df, free, ps, ss, who, last, jq, curl

sudo access to read:

/var/log/auth.log (for SSH detection)
Shell history files in /home/* or /Users/*
Email system configured (mail command)

Valid Discord Webhook URL

Write permission to home directory for logs and trace files

📥 Installation
Save the script as sysmonitor.sh.

Make it executable: chmod +x sysmonitor.sh

Edit configuration variables at the top of the script:

EMAIL_RECIPIENT="user@example.com"
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
CPU_THRESHOLD=80 # CPU usage alert threshold (%)
MEM_THRESHOLD=80 # Memory usage alert threshold (%)
DISK_THRESHOLD=80 # Disk usage alert threshold (%)
ALERT_LOOKBACK=10 # SSH log audit window in days
TRACEFILE="$HOME/sysmonitor_trace.json"
LOGFILE="$HOME/sysmonitor_alerts.log"
ALERT_FILE="$HOME/sysmonitor_combined_alerts.txt"
MAIL_LOG="$HOME/sysmonitor_mail_errors.log"

🚀 Usage
Manual Run
./sysmonitor.sh
Run Periodically with cron
Edit crontab:

crontab -e
If no sudo needed:

*/5 * * * * /path/to/sysmonitor.sh >> $HOME/sysmonitor_cron.log 2>&1
If sudo is required (for auth.log access):

Add to visudo:
username ALL=(ALL) NOPASSWD: /path/to/sysmonitor.sh
Cron entry:
*/5 * * * * sudo /path/to/sysmonitor.sh >> $HOME/sysmonitor_cron.log 2>&1

📤 Output
Log File: $HOME/sysmonitor_alerts.log — detailed monitoring logs
Alert File: $HOME/sysmonitor_combined_alerts.txt — critical alerts
JSON Trace File: $HOME/sysmonitor_trace.json — Chrome/Perfetto compatible
Email Errors: $HOME/sysmonitor_mail_errors.log
Console Output: Real-time metrics with visual ASCII bars

🔍 Monitored Areas
Category	Description	Command/Source
CPU Usage	Alerts if usage > threshold	awk + /proc/stat, bc
Memory Usage	Alerts if usage > threshold	awk + /proc/meminfo
Disk Usage	Monitors / root partition	df -P
Top Processes	Top 5 by memory	ps --sort=-%mem
User Logins	Logged-in users, last 5 logins	w, last -F
Shell History	Commands from .bash_history, .zsh_history	cat, grep
Brute-Force	Failed SSH attempts + source IP count	grep, awk, uniq
Network	Active connections, top remote IPs	ss -s, ss -tn
Uptime	Shows system uptime	uptime
Trace Output	CPU/MEM/DISK in Chrome Trace format JSON	jq, echo → $TRACEFILE

🛠 Troubleshooting
Issue	Fix
Permission Denied	Add user to adm group: sudo usermod -aG adm username
Missing Commands	Install required tools: sudo apt install jq curl
Email Fails	Verify SMTP/mail setup, check $MAIL_LOG
Discord Alerts Fail	Check webhook URL, network connectivity
Trace File Grows	Add trace reset logic: see below

🧚 Testing Tips
Stress-test resources:
sudo apt install stress
stress --cpu 4 --timeout 20
stress --vm 2 --timeout 20
Trigger brute-force detection: Attempt SSH logins with wrong passwords.

Validate Alerts:

Check $ALERT_FILE
Discord notifications
Email inbox
Visualize trace:

Chrome: chrome://tracing
Perfetto: https://ui.perfetto.dev/
🔒 Security Notes
Keep your Discord webhook URL private — use environment variables if possible.
Limit sudo access to essential operations only.
Regularly inspect $LOGFILE and $ALERT_FILE.
Monitor trace file growth — especially if running via cron.

🔁 Cron & JSON Trace Behavior
Each run appends resource usage as a valid JSON event to $TRACEFILE.

This allows continuous tracing over time.

You can visualize trends using:

chrome://tracing
Perfetto Viewer
📄 Short Report: Monitoring Summary

✅ What We Monitored
System Resources: CPU, memory, disk usage (with thresholds)
Processes: Top 5 memory consumers
User Activity: Logged-in users, login history, shell commands
Brute-Force Attacks: Failed SSH login attempts with IPs
Network: Active connections and remote IP usage
System Uptime
Performance Trace: JSON-formatted data over time
🔍 How We Monitored
Using native tools: awk, bc, df, free, ps, ss, w, last, jq, grep, curl

Files parsed: /proc/*, /var/log/auth.log, shell histories

Alerts sent to:

📧 Email
🔔 Discord
Data stored in:

sysmonitor_trace.json for visualization
sysmonitor_alerts.log and sysmonitor_combined_alerts.txt

🌟 Why This Approach
Minimal Dependencies: Uses tools pre-installed on most Linux systems
Security-Oriented: Includes login audits and brute-force detection
Extensible: Modular design for easy customization
Visual Feedback: ASCII bars + trace format support
Flexible Alerting: Covers modern (Discord) and traditional (email) needs