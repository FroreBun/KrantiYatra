# 🚄 Train Delay Monitoring program

A local,privacy-friendly shell-based dashboard for monitoring train delays, generating real-time summaries, and exporting formatted CSV reports.  
Users view the dashboard in their browser via localhost, and download key datasets with a single click. No PDF generation, no chart images—just secure, readable HTML and CSV.

## Features

- **Simulated & live train data (JSON → CSV)**
- **Dashboard HTML auto-generated, viewable on localhost**
- **Summary statistics: total trains, delayed count, average delay**
- **Downloadable CSV direct from dashboard**
- **Temporary files auto-cleaned for a neat workspace**
- **Easy setup, pure Bash + jq (only Python for the local server)**

---

## Quick Start
- it clone https://github.com/FroreBun/KrantiYatra/new/main?filename=README.md
- cd ~/KrantiYatra
- chmod +x trans_monitor.sh
- ./trans_monitor.sh run to run
- ./trans_monitor.sh serve to host website in localhost:8000
- ./trans_monitor.sh clean to clean up the data in local user directory


---

## Usage

- **View status in browser:**  
  Open [`http://localhost:8000/report_DATE.html`](http://localhost:8000/report_DATE.html)
- **Download summary:**  
  Click the "Download CSV" button at the top of the dashboard page.
- **No PDFs or chart images:**  
  Output is always clean, readable HTML and properly formatted CSV only.
- **Customization:**  
  Modify sample data, add train routes, or plug in APIs in `fetch_sample_data`.

---

## File Structure

$PROJECT_ROOT
├─ train_monitor.sh # Main script
├─ README.md # Project info
├─ .local/share/train_monitor/
│ ├─ data/ # Raw and sample data (JSON)
│ ├─ reports/ # Dashboards and CSV reports (HTML/CSV only)
│ ├─ logs/ # Operation logs
│ └─ archive/ # Old logs/reports (archived)


## Requirements

- Bash (macOS and Linux)
- `jq` (for JSON parsing)
- Python 3 (for the built-in localhost web server)
- No other dependencies

---

## License

MIT License (see LICENSE file)

---
