#!/bin/bash

# ==== Configuration ====
CONFIG_FILE="$HOME/sysmonitor.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Missing config file: $CONFIG_FILE"
    exit 1
fi

LOGFILE="$HOME/sysmonitor_alerts.log"
MAIL_LOG="$HOME/sysmonitor_mail_errors.log"
TRACEFILE="$HOME/sysmonitor_trace.json"
ALERT_FILE="$HOME/sysmonitor_combined_alerts.txt"

EMAIL_SUBJECT="System Monitoring Alert"
ALERT_LOOKBACK="${ALERT_LOOKBACK:-10 days ago}"


CPU_THRESHOLD=${CPU_THRESHOLD:-3}
MEM_THRESHOLD=${MEM_THRESHOLD:-5}
DISK_THRESHOLD=${DISK_THRESHOLD:-10}

# ==== Safety Checks ====
if ! touch "$ALERT_FILE" &>/dev/null; then
    echo " Error: Cannot write to $ALERT_FILE. Check permissions or run with sudo." | tee -a "$LOGFILE"
    ALERT_FILE="$HOME/sysmonitor_combined_alerts.txt"
    if ! touch "$ALERT_FILE" &>/dev/null; then
        echo " Fallback error: Cannot write to $ALERT_FILE (HOME). Exiting." | tee -a "$LOGFILE"
        exit 1
    else
        echo " Using fallback ALERT_FILE location: $ALERT_FILE" | tee -a "$LOGFILE"
    fi
fi
for cmd in awk bc df free ps ss who last jq curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo " Error: Required command '$cmd' not found" | tee -a "$LOGFILE"
        exit 1
    fi
done

# ==== Functions ====
send_discord_alert() {
    local message="$1"
    local payload=$(jq -n --arg content "$(printf "%b" "$message")" '{content: $content}')
    curl -s -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK_URL" >/dev/null 2>&1
}

draw_bar() {
    local percent=$1
    local bar_length=${2:-30}
    local filled_char=${3:-"█"}
    local empty_char=${4:-"░"}
    local show_percent=${5:-true}
    local label=${6:-""}
    if [ -z "$percent" ] || ! [[ "$percent" =~ ^[0-9]+$ ]] || [ "$percent" -gt 100 ]; then
        echo "Error: Invalid percent for draw_bar" >&2
        return 1
    fi
    local filled_length=$((percent * bar_length / 100))
    local empty_length=$((bar_length - filled_length))
    local green="\e[32m"
    local gray="\e[90m"
    local reset="\e[0m"
    local bar=""
    bar+="["
    bar+="${green}"
    bar+=$(printf "%0.s${filled_char}" $(seq 1 $filled_length))
    bar+="${gray}"
    bar+=$(printf "%0.s${empty_char}" $(seq 1 $empty_length))
    bar+="${reset}"
    bar+="]"
    if [ -n "$label" ]; then
        bar="$label: $bar"
    fi
    if [ "$show_percent" = true ]; then
        bar+=" ${percent}%"
    fi
    echo -e "$bar"
}

# ==== Gather Basic Info ====
CURRENT_USER=$(whoami)
LAST_USER=$(last -n 1 -w | head -n 1 | awk '{print $1}')

# ==== Start report ====
> "$ALERT_FILE"
echo -e "\n==================== System Monitoring Report ====================" | tee -a "$LOGFILE"
echo "Date: $(date)" | tee -a "$LOGFILE"
echo "Current User: $CURRENT_USER" | tee -a "$LOGFILE"
echo "Last Login User: $LAST_USER" | tee -a "$LOGFILE"
echo "==================================================================" | tee -a "$LOGFILE"

# ==== CPU Usage ====
prev_idle=$(awk '/^cpu / {print $5}' /proc/stat)
prev_total=$(awk '/^cpu / {sum=0; for(i=2;i<=8;i++) sum+=$i; print sum}' /proc/stat)
sleep 1
curr_idle=$(awk '/^cpu / {print $5}' /proc/stat)
curr_total=$(awk '/^cpu / {sum=0; for(i=2;i<=8;i++) sum+=$i; print sum}' /proc/stat)
delta_idle=$((curr_idle - prev_idle))
delta_total=$((curr_total - prev_total))
cpu_usage=0
if [ "$delta_total" -ne 0 ]; then
    cpu_usage=$(echo "scale=1; (1 - $delta_idle / $delta_total) * 100" | bc)
fi
echo -e "\n==== CPU Usage ====" | tee -a "$LOGFILE"
echo -n "Usage: $cpu_usage% " | tee -a "$LOGFILE"
draw_bar "${cpu_usage%.*}" | tee -a "$LOGFILE"
echo | tee -a "$LOGFILE"
if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
    echo "  High CPU usage detected: $cpu_usage%" | tee -a "$LOGFILE"
    echo "High CPU usage: $cpu_usage%" >> "$ALERT_FILE"
fi

# ==== Memory Usage ====
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used=$((mem_total - mem_available))
mem_percent=$((mem_used * 100 / mem_total))
echo -e "\n==== Memory Usage ====" | tee -a "$LOGFILE"
echo -n "Usage: $mem_percent% ($((mem_used / 1024))MB / $((mem_total / 1024))MB) " | tee -a "$LOGFILE"
draw_bar "$mem_percent" | tee -a "$LOGFILE"
echo | tee -a "$LOGFILE"
if [ "$mem_percent" -gt "$MEM_THRESHOLD" ]; then
    echo "  High memory usage: $mem_percent%" | tee -a "$LOGFILE"
    echo "High memory usage: $mem_percent%" >> "$ALERT_FILE"
fi

# ==== Top 5 Memory-Intensive Processes ====
echo -e "\n==== Top 5 Memory Intensive Processes ====" | tee -a "$LOGFILE"
ps --no-headers -eo pid,user,%mem,comm --sort=-%mem | head -n 5 | tee -a "$LOGFILE"

# ==== Disk Usage ====
disk_usage=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')
echo -e "\n==== Disk Usage on / ====" | tee -a "$LOGFILE"
echo -n "Usage: $disk_usage% " | tee -a "$LOGFILE"
draw_bar "$disk_usage" | tee -a "$LOGFILE"
echo | tee -a "$LOGFILE"
if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
    echo "  Disk usage high on /: $disk_usage%" | tee -a "$LOGFILE"
    echo "Disk usage high : $disk_usage%" >> "$ALERT_FILE"
fi

# ==== User Login & Activity Audit ====
# Replaced original SSH Login Audit and User Login Info sections
echo -e "\n==== User Login & Activity Audit ====" | tee -a "$LOGFILE"
echo "INFO: Currently logged-in users:" | tee -a "$LOGFILE"
w | tee -a "$LOGFILE"
echo | tee -a "$LOGFILE"

# Show last real login (excluding system boot entries)
last_login=$(last -F | grep -v "system boot" | head -n 5)
if [ -n "$last_login" ]; then
    echo "INFO: Last login recorded:" | tee -a "$LOGFILE"
    echo "$last_login" | tee -a "$LOGFILE"
else
    echo "INFO: No previous login records found." | tee -a "$LOGFILE"
fi
echo | tee -a "$LOGFILE"

# Recent commands from user histories
echo -e "\n-- Recent Commands from Shell History --" | tee -a "$LOGFILE"
for home in /home/* /Users/*; do
    if [ -d "$home" ]; then
        user=$(basename "$home")
        for histfile in "$home/.bash_history" "$home/.zsh_history"; do
            if [ -r "$histfile" ]; then
                echo "History for $user ($(basename "$histfile")):" | tee -a "$LOGFILE"
                tail -n 5 "$histfile" | sed 's/^/  /' | tee -a "$LOGFILE"
                echo | tee -a "$LOGFILE"
            fi
        done
    fi
done

# Brute-force attack detection
if [ -r /var/log/auth.log ]; then
    failed_ips=$(grep "Failed password" /var/log/auth.log | \
        awk '{for(i=1;i<=NF;i++){if($i=="from"){print $(i+1)}}}' | \
        sort | uniq -c | sort -nr)
    if [ -n "$failed_ips" ]; then
        alert_msg=$(printf "=== Brute-Force Attack Check ===\n  Source IPs:\n  %s\n" "$failed_ips")
        echo "$alert_msg" | tee -a "$LOGFILE"
        echo "$alert_msg" >> "$ALERT_FILE"
    else
        echo "No failed login attempts found." | tee -a "$LOGFILE"
    fi
else
    echo "Cannot read /var/log/auth.log (permission denied)." | tee -a "$LOGFILE"
fi

# ==== Network Summary ====
echo -e "\n==== Network Summary ====" | tee -a "$LOGFILE"
echo "Active Connection States:" | tee -a "$LOGFILE"
ss -s | tee -a "$LOGFILE"
echo -e "\nTop 5 Remote IPs by Connections:" | tee -a "$LOGFILE"
ss -tn state established | awk '{print $5}' | cut -d':' -f1 | sort | uniq -c | sort -nr | head -n 5 | awk '{print "- "$2 " (" $1 " connections)"}' | tee -a "$LOGFILE"

# ==== System Uptime ====
echo -e "\n==== System Uptime ====" | tee -a "$LOGFILE"
uptime | tee -a "$LOGFILE"

# ==== JSON Trace Output ====
# ==== JSON Trace Output ====
timestamp_ms=$(date +%s%3N) # milliseconds

# Generate new trace events
new_events=$(jq -n --arg time "$timestamp_ms" \
      --arg cpu "$cpu_usage" \
      --arg mem "$mem_percent" \
      --arg disk "$disk_usage" \
      '[
        {
          "name": "CPU Usage",
          "ph": "C",
          "ts": ($time|tonumber),
          "dur": 0,
          "pid": 0,
          "tid": 0,
          "args": { "usage_percent": ($cpu|tonumber) }
        },
        {
          "name": "Memory Usage",
          "ph": "C",
          "ts": ($time|tonumber),
          "dur": 0,
          "pid": 0,
          "tid": 1,
          "args": { "usage_percent": ($mem|tonumber) }
        },
        {
          "name": "Disk Usage",
          "ph": "C",
          "ts": ($time|tonumber),
          "dur": 0,
          "pid": 0,
          "tid": 2,
          "args": { "usage_percent": ($disk|tonumber) }
        }
      ]')

# Initialize TRACEFILE as an empty JSON array if it doesn't exist
if [ ! -f "$TRACEFILE" ]; then
    echo "[]" > "$TRACEFILE"
fi

# Append new events to TRACEFILE
# Read existing events, merge with new events, and write back
jq --argjson new "$new_events" '. + $new' "$TRACEFILE" > "${TRACEFILE}.tmp" && mv "${TRACEFILE}.tmp" "$TRACEFILE"

# ==== Build Alert Message ====
alert_msg="System Alert - Current user: *$CURRENT_USER*, Last login user: *$LAST_USER* - $(date '+%Y-%m-%d %H:%M:%S')"
if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
    alert_msg+="\n\nHigh CPU usage: ${cpu_usage}%"
fi
if [ "$mem_percent" -gt "$MEM_THRESHOLD" ]; then
    alert_msg+="\nHigh memory usage: ${mem_percent}%"
fi
if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
    alert_msg+="\nHigh disk usage: ${disk_usage}%"
fi
if [ -n "$failed_ips" ]; then
    alert_msg+="\nFailed SSH logins:\n$failed_ips"
else
    alert_msg+="\nNo failed SSH login attempts."
fi

if grep -q . "$ALERT_FILE"; then
    send_discord_alert "$alert_msg"
fi

# ==== Email Alerting ====
if [ -s "$ALERT_FILE" ]; then
    alert_body=$(cat "$ALERT_FILE")
    echo "$alert_body" | mail -s "$EMAIL_SUBJECT" "$EMAIL_RECIPIENT" 2>>"$MAIL_LOG"
    echo "Email alert sent to $EMAIL_RECIPIENT" | tee -a "$LOGFILE"
else
    echo "No email alert needed (no critical alerts found)." | tee -a "$LOGFILE"
fi

echo -e "\n==================== End of Report ====================" | tee -a "$LOGFILE"