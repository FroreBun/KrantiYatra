#!/bin/bash
################################################################################
# Train Delay Monitoring System - HTML/CSV Only - Localhost Dashboard
################################################################################

CONFIG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/train_monitor"
DATA_DIR="$CONFIG_DIR/data"
LOG_DIR="$CONFIG_DIR/logs"
REPORT_DIR="$CONFIG_DIR/reports"
ARCHIVE_DIR="$CONFIG_DIR/archive"

DELAY_THRESHOLD=15   # in minutes
API_TYPE="${TRAIN_API_TYPE:-sample}"
USER_EMAIL="${TRAIN_MONITOR_EMAIL:-user@example.com}"
LOCALHOST_PORT=8000

mkdir -p "$DATA_DIR" "$LOG_DIR" "$REPORT_DIR" "$ARCHIVE_DIR"

log() {
    local level="$1"; shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_DIR/monitor.log"
}

################################################################################
# Generate sample train data (expand as needed)
################################################################################
fetch_sample_data() {
    local out="$1"
    local date_str=$(date '+%Y-%m-%d')
    log INFO "Generating sample train data"
    echo '{"trains":[' >"$out"
    for i in {1..15}; do
        local route="Route $((350 + i))"
        local loc="Station $((i % 7 + 1))"
        local train_id="TRN$((1000+i))"
        local hour=$((8 + i))
        local sched_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$date_str $hour:00:00" +%s)
        local rand=$((RANDOM % 100))
        local delay_min=$((rand / 5))
        local actual_epoch=$((sched_epoch + delay_min * 60))
        local sched_time=$(date -r "$sched_epoch" '+%Y-%m-%dT%H:%M:%S')
        local actual_time=$(date -r "$actual_epoch" '+%Y-%m-%dT%H:%M:%S')
        local status=$([ "$delay_min" -gt "$DELAY_THRESHOLD" ] && echo "delayed" || echo "on_time")
        printf '  {"train_id":"%s","route":"%s","location":"%s","scheduled_arrival":"%s","actual_arrival":"%s","delay_min":%d,"status":"%s"}' \
          "$train_id" "$route" "$loc" "$sched_time" "$actual_time" "$delay_min" "$status" >>"$out"
        [ "$i" -lt 15 ] && echo "," >>"$out"
    done
    echo ']}' >>"$out"
}

################################################################################
# Transform sample data -> CSV
################################################################################
process_train_data() {
    local json="$1"
    local csv="$2"
    log INFO "Generating CSV from train data"
    echo "Train_ID,Route,Location,Scheduled,Actual,Delay_Minutes,Status" >"$csv"
    jq -r '.trains[] | [.train_id, .route, .location, .scheduled_arrival, .actual_arrival, .delay_min, .status] | @csv' "$json" >>"$csv"
}

################################################################################
# Main HTML Dashboard - View + Download
################################################################################
generate_html_dashboard() {
    local csv="$1"
    local html="$2"
    local date_str=$(date '+%Y-%m-%d')

    log INFO "Generating HTML dashboard"
    local total=$(awk -F',' 'NR>1 {c++} END{print c+0}' "$csv")
    local delayed=$(awk -F',' 'NR>1 && $6>'$DELAY_THRESHOLD' {c++} END{print c+0}' "$csv")
    local avg_delay=$(awk -F',' 'NR>1 {sum+=$6} END{if(NR>1) printf "%.1f",sum/(NR-1); else print 0}' "$csv")

    cat >"$html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Train Service Dashboard - ${date_str}</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Segoe UI, Arial, sans-serif; background: #f6f8fa; color: #252525; }
        .header { background: #30446d; color: #fff; padding: 2rem 1rem; }
        .cards { display: flex; gap: 2rem; margin: 2rem 0; }
        .card { background: #fff; border-radius: 12px; box-shadow: 0 0 10px #e3e3e3; padding: 1rem 2rem; text-align: center; min-width: 140px; }
        .card strong { font-size: 2em; color: #3050a0; }
        table { background: #fff; border-radius: 12px; width: 100%; border-collapse: collapse; margin:2rem 0;}
        th, td { padding: .6em 1em; border-bottom: 1px solid #e5e7eb; }
        th { background: #30446d; color: #fff; letter-spacing: .05em; }
        tr:nth-child(even) { background: #f1f5fa; }
        .downloads { margin:2rem 0; }
        .downloads a { background: #667eea; color: #fff; padding:.7em 1.2em; border-radius: 5px; text-decoration:none; margin-right:1em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚄 Train Delay Monitoring Dashboard</h1>
        <div>Report Date: $date_str</div>
    </div>
    <div class="cards">
        <div class="card"><div>Total Trains</div><strong>$total</strong></div>
        <div class="card"><div>Delayed (&gt;$DELAY_THRESHOLD min)</div><strong>$delayed</strong></div>
        <div class="card"><div>Average Delay</div><strong>${avg_delay} min</strong></div>
    </div>
    <div class="downloads">
        <a href="delays_${date_str}.csv" download>Download CSV</a>
    </div>
    <h2>Train Performance Records</h2>
    <table>
        <thead>
            <tr>
                <th>Train ID</th>
                <th>Route</th>
                <th>Location</th>
                <th>Scheduled</th>
                <th>Actual</th>
                <th>Delay (min)</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
EOF

    awk -F',' 'NR>1 {
        printf "<tr>";
        for(i=1;i<=NF;i++) printf "<td>%s</td>", $i;
        printf "</tr>\n";
    }' "$csv" >> "$html"

    cat >>"$html" <<EOF
        </tbody>
    </table>
    <footer style="padding:2em 1em; color:#888;">Automated dashboard - local & secure. No PDF generated - download summary CSV above.</footer>
</body>
</html>
EOF
}

################################################################################
# Clean temporary files (leave only HTML and summary CSV in reports)
################################################################################
cleanup_reports_folder() {
    local report_dir="$REPORT_DIR"
    find "$report_dir" -type f ! -name 'delays_*.csv' ! -name 'report_*.html' -delete
    log INFO "Cleanup complete: Only dashboard and main CSV kept."
}

################################################################################
# Start localhost web server (python3)
################################################################################
serve_dashboard() {
    log INFO "Serving dashboard at http://localhost:$LOCALHOST_PORT/"
    cd "$REPORT_DIR" || exit 1
    python3 -m http.server "$LOCALHOST_PORT"
}

################################################################################
# Full pipeline
################################################################################
run_monitoring() {
    local date_str=$(date '+%Y-%m-%d')
    local json="$DATA_DIR/trains_$date_str.json"
    local csv="$REPORT_DIR/delays_${date_str}.csv"
    local html="$REPORT_DIR/report_${date_str}.html"

    fetch_sample_data "$json"
    process_train_data "$json" "$csv"
    generate_html_dashboard "$csv" "$html"
    cleanup_reports_folder
    log INFO "Dashboard at $html"
}

################################################################################
# CLI Menu
################################################################################
case "$1" in
    run) run_monitoring ;;
    serve|start-server) serve_dashboard ;;
    clean) cleanup_reports_folder ;;
    help|--help|-h|"")
        echo "Usage: $0 run            # Generate dashboard"
        echo "       $0 serve          # Start HTTP server on localhost:8000"
        echo "       $0 clean          # Remove temp files in $REPORT_DIR"
        echo "       $0 help           # Show help"
        ;;
    *)
        echo "Unknown command: $1" && exit 1
        ;;
esac

