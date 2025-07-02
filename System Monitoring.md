System Monitoring 

1. Configuration and Setup
• Setting Important Settings
Things like log file names, warning levels, and who gets alerts are stored in one place.
→ This makes it easy to change without touching the rest of the script.
• Check File Access
The script checks if it can write to the log and alert files.
→ If it can’t, it tries a backup location. This avoids missing important data.
• Check for Needed Tools
It checks if required tools (like awk, bc, ps, curl, etc.) are installed.
→ If something is missing, the script stops to prevent errors.

3. Functions
• send_discord_alert()
Sends alerts to a Discord channel.
→ Uses curl and jq to format and send the message safely and correctly.
• draw_bar()
Shows colorful bars to display usage (like CPU and memory).
→ Makes the results easier to read than just showing numbers.

4. Basic System Info
• whoami, last
Shows who is currently logged in and recent login history.
→ Helpful for knowing who used the system and when.

5. CPU Usage
Checks system CPU usage by reading a special system file twice (1 second apart).
→ This method gives more accurate results than using some common tools.

6. Memory Usage
Reads memory data from the system directly.
→ Calculates how much memory is being used and shows it clearly.

7. Top 5 Memory-Hungry Programs
Lists the top 5 programs using the most memory.
→ Helps find what’s slowing the system down.

8. Disk Usage
Checks how full the main hard drive is.
→ Shows the usage as a percentage. Works well on most Linux systems.

9. User Login and Activity
Shows who’s logged in now and past login details.
Also reads the last few commands typed by users.
→ Can help spot suspicious activity.

10. Brute-force Attack Detection
Looks for failed password attempts in system logs.
→ Collects and counts the IP addresses of possible attackers.

11. Network Summary
Shows network connection stats and top 5 remote IPs connected.
→ Helps see who’s connected to your system and how active the network is.

12. System Uptime
Tells how long the system has been running since the last reboot.

13. JSON Trace Output
Creates a detailed data file that can be used with tools like Chrome’s trace viewer.
→ Helps visualize system performance over time.

14. Alert Message Creation
Builds a full alert message including:
User info, time, high resource usage, and failed logins.
Only sends alerts if there’s something important to report.
→ This avoids unnecessary messages.

15. Email Alerts
Sends alert emails when needed using the mail command.
→ Simple, built-in way to notify admins without extra software.
Summary
This script is:

Accurate – It checks directly from system files.
Simple – Uses standard tools that work on most Linux systems.
Clear – Easy-to-read output with visual bars and clean text.
Safe – Handles errors and file access issues properly.
Flexible – Sends alerts to both Discord and email.
Well-organized – Uses functions to keep things tidy and easy to update.
Command/Tool Reference
Command/Tool	Purpose/Function	Why Used / Advantages
whoami	Shows current logged-in user	Simple, reliable way to get the current user
last	Shows last login records	Provides history of recent logins including usernames and timestamps
awk	Text processing and extraction	Lightweight, powerful for parsing and extracting specific fields from text/files
bc	Performs floating-point arithmetic	Needed for precise CPU usage calculation (bash lacks float arithmetic)
df	Shows disk space usage	Standard tool to check disk usage with portable and consistent output
free	Reports memory usage	Simple, fast way to get total and available memory
ps	Lists running processes	Useful for sorting and filtering top memory-consuming processes
ss	Displays network socket stats and connection info	More modern, faster, and feature-rich replacement for netstat
who	Lists currently logged-in users	Useful for auditing active sessions
jq	JSON parsing and generation	Essential for creating and updating JSON trace output
curl	Sends HTTP requests	Lightweight, widely available for POSTing alert JSON to Discord
grep	Searches text using regex	Efficient filtering of logs (e.g., failed login attempts)
cut	Extracts portions of text lines	Simple way to isolate IP addresses from connection info
sort	Sorts lines of text	Used for counting and ordering occurrences (e.g., failed IP attempts)
uniq	Filters unique lines and counts duplicates	Combined with sort to summarize repeated entries
head	Extracts top N lines	Shows only top records (top memory processes, recent logins)
tail	Extracts last N lines	Used to show recent command history
seq	Generates sequences of numbers	Used to build progress bars visually
sleep	Pauses script execution	Allows time interval to measure CPU usage changes accurately
printf	Formatted output	Used in building progress bars and formatting alert messages
test, [ ]	Conditional checks	For validating inputs and controlling logic
tee	Logs output to file and stdout	Allows simultaneous logging to console and logfile
mail	Sends email alerts	Sends email notifications of critical alerts
