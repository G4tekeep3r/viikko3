#!/usr/bin/env bash

OUTPUT_DIR="/var/www/html/viikko3"
GITHUB_URL="https://github.com/G4tekeep3r/viikko3.git"
TEMP_FILE="$(mktemp "$OUTPUT_DIR/.index.XXXXXX")"

# Function: returns either OK or WARNING based on percentage
get_disk_status() {
    local usage="$1"
    if [ "$usage" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

GENERATED_AT=$(TZ="Europe/Helsinki" date '+%Y-%m-%d %H:%M:%S %Z')
UPTIME_TEXT=$(uptime -p)
DISK_PERCENT=${1:-$(df -P / | awk 'NR == 2 {print $5}' | tr -d '%')}
DISK_USAGE="${DISK_PERCENT}%"
DISK_STATUS=$(get_disk_status "$DISK_PERCENT")
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_AVAILABLE=$(free -m | awk '/Mem:/ {print $7}')


cat > "$TEMP_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Week 3 – Server Status Report</title>
    <style>
        body {
            font-family: system-ui, sans-serif;
            max-width: 900px;
            margin: 40px auto;
            padding: 0 20px;
            line-height: 1.6;
            background: #f1f5f9;
            color: #172033;
        }

        h1, h2 {
            color: #173b65;
        }

        section {
            margin: 24px 0;
            padding: 24px;
            background: white;
            border-radius: 12px;
        }

        .table-container {
            overflow-x: auto;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

        th, td {
            border: 1px solid #cbd5e1;
            padding: 12px;
            text-align: left;
        }

        th {
            background: #dbeafe;
        }

        code {
            background: #e2e8f0;
            padding: 2px 5px;
            border-radius: 4px;
            overflow-wrap: anywhere;
        }

        a {
            color: #1746a2;
        }

        .note {
            color: #475569;
        }
    </style>
</head>
<body>
    <header>
        <h1>Server Status Report</h1>
        <p>Week 3: Linux command line and Bash scripting</p>
        <p>
           This page automatically updates server status report for my Linux server in CSC cPouta.
           A bash script collects current date and time, uptime, root filesystem disk usage and RAM information,
           and generates this HTML page. The report also shows a disk space status that changes
           from OK to WARNING when disk usage reaches 80%.
        </p>
    </header>

    <section>
        <h2>Current server status</h2>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Information</th>
                        <th scope="col">Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <th scope="row">Report generated</th>
                        <td>$GENERATED_AT</td>
                    </tr>
                    <tr>
                        <th scope="row">Server uptime</th>
                        <td>$UPTIME_TEXT</td>
                    </tr>
                    <tr>
                        <th scope="row">Root filesystem disk usage</th>
                        <td>$DISK_USAGE</td>
                    </tr>
                    <tr>
                        <th scope="row">Disk space status</th>
                        <td>$DISK_STATUS</td>
                    </tr>
                    <tr>
                        <th scope="row">Total RAM</th>
                        <td>$MEM_TOTAL MiB</td>
                    </tr>
                    <tr>
                        <th scope="row">Available RAM</th>
                        <td>$MEM_AVAILABLE MiB</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <p>
            Disk space status is <strong>OK</strong> below 80% usage
            and <strong>WARNING</strong> at 80% or above.
        </p>

        <p class="note">
            Bash generates this report once per minute.
            Wait approximately 1–2 minutes and reload the page
            to see a new generation time.
        </p>
    </section>

    <section>
        <h2>Commands used</h2>
        <ul>
            <li>
                <code>date</code>:
                displays the current date, time and time zone
                using the format specified in the script.
            </li>
            <li>
                <code>uptime -p</code>:
                displays how long the server has been running.
            </li>
            <li>
                <code>df -P / | awk 'NR == 2 {print &#36;5}'</code>:
                passes filesystem information to awk, which extracts
                the usage percentage from the second row.
            </li>
            <li>
                <code>free -m</code>:
                displays memory information in mebibytes (MiB).
            </li>
        </ul>
    </section>

    <section>
        <h2>How the script works</h2>
        <p>
            The script collects server information using Linux commands
            and stores the results in Bash variables through command
            substitution. A function uses an if statement to determine
            the disk space status.
        </p>
        <p>
            The script generates a temporary HTML file and then moves
            the completed file into place as index.html.
            Nginx serves this file at /viikko3/.
        </p>
        <p>
            The disk space function reads the current disk usage percentage of the root filesystem
            and returns a status based on it. An if statement compares the value to a threshold:
            usage below 80% gives "OK", and 80% or more gives "WARNING". The result is then stored
            in a variable and inserted into the HTML report.
        </p>
        <p>
            Example of piping from my script:
        </p>
        <p>
            <code>df -P / | awk 'NR==2 {print &#36;5}' | tr -d '%'</code>
        </p>
        <p>
            <code>df</code> prints the disk usage table, <code>awk</code> picks the usage column from the second line,
            and <code>tr</code> removes the % sign so the value can be compared as a number.
        </p>
    </section>

    <section>
        <h2>Scheduling</h2>
        <p>
            I used cron to run the script automatically. The schedule is defined in my user's crontab
            with the following line:
        </p>
        <p>
            <code>* * * * * /home/ubuntu/viikko3/report.sh</code>
        </p>
        <p>
            The five asterisks mean that the script runs every minute of every
            hour, day, month and weekday. For cron finding the script, the full path is used.
        </p>
        <p>
            Cron service is enabled in systemd, so it starts automatically when
            the virtual machine reboots. I checked this with <code>systemctl is-enabled cron</code>
            and confirmed with the reboot test that the report continued to update.
        </p>
    </section>

    <section>
        <h2>Test results</h2>

        <h3>Syntax check and manual execution</h3>
        <p>
            I ran <code>bash -n report.sh</code> and it produced no output, which means there are
            no syntax errors. I then ran the script manually with <code>./report.sh</code>.
            It completed without errors and created /var/www/html/viikko3/index.html. I opened
            viikko3 in the browser and the report showed the current time, uptime, disk usage and memory.
        </p>

        <h3>Disk space status tests</h3>
        <p>
            I tested the status logic by giving temporary input values to the script as a parameter.
        </p>
        <ul>
            <li><code>./report.sh 50</code> : 50% disk usage</li>
            <li><code>./report.sh 80</code> : 80% disk usage</li>
            <li><code>./report.sh 90</code> : 90% disk usage</li>
        </ul>
        <p>
            After the tests I ran <code>./report.sh</code> without a parameter to restore real disk usage percentage.
        </p>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Test input</th>
                        <th scope="col">Expected status</th>
                        <th scope="col">Actual status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>50%</td>
                        <td>OK</td>
                        <td>OK</td>
                    </tr>
                    <tr>
                        <td>80%</td>
                        <td>WARNING</td>
                        <td>WARNING</td>
                    </tr>
                    <tr>
                        <td>90%</td>
                        <td>WARNING</td>
                        <td>WARNING</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <h3>Automatic updates</h3>
        <p>
            Cron runs the script every minute. I reloadeed the page three times
            and recorded the generation times of consecutive updates:
        </p>
        <ul>
            <li>2026-11-15 13:07:01</li>
            <li>2026-11-15 13:08:01 (one minute later)</li>
            <li>2026-11-15 13:09:01 (one minute later)</li>
        </ul>
        <p>The generation time changed after each update, so the schedule works.</p>


        <h3>Reboot test</h3>
        <p>
            I rebooted the virtual machine at 13:05 (EET) using <code>sudo reboot</code>.
            After reconnecting I checked that the cron service was enabled and running.
        </p>
        <ul>
            <li>The Week 2 application opened normally.</li>
            <li>The Week 3 page opened normally.</li>
            <li>The server uptime on the report had restarted from a few minutes.</li>
            <li>The generation time continued to change after the reboot (13:05:03 and 13:07:01).
        </ul>
    </section>

    <section>
        <h2>A problem solved or a lesson learned</h2>
        <p>
           During the lectures I understood that I would need to edit the Nginx configuration file for the Week 3 page to work,
           as I had done for the Week 2 application. Later I realised that this was not necessary for this exercise.
        </p>
        <p>
           The Week 2 application (Python) is running on its own port, so Nginx needs a seperate location block
           with a proxy pass to forward requests to it. The Week 3 report is only a static HTML file.
           The existing location block already serves files from <code>/var/www/html/</code>, so a request to
           <code>/viikko3/</code> returns <code>/var/www/html/viikko3/index.html</code> without any changes.
        </p>
        <p>
           What I learned is that serving a static page only requires the file to be in the right directory with
           readable permissions, while an application needs a reverse proxy configuration.
           Not editing the Nginx file also meant that the Week 2 application could not be broken by accident.
        </p>
    </section>

    <footer>
        <p><a href="$GITHUB_URL">View the source code on GitHub</a></p>
    </footer>
</body>
</html>
EOF


chmod 644 "$TEMP_FILE"
mv "$TEMP_FILE" "$OUTPUT_DIR/index.html"
