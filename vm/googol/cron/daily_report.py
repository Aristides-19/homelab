import subprocess
import os
import requests
from datetime import datetime, timedelta

# Load .env from same directory
env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
if os.path.exists(env_path):
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                key, _, value = line.partition('=')
                os.environ[key.strip()] = value.strip().strip('"').strip("'")

# Configuration
TOKEN = os.environ.get("TELEGRAM_TOKEN", "")
ID = os.environ.get("TELEGRAM_GROUP_ID", "")
THREAD_ID = os.environ.get("TELEGRAM_THREAD_ID", "")
INTERFACE = "ens4"
LIMIT_GB = 180

def get_vnstat_output(args):
    """Executes vnstat with specific arguments and returns the output text."""
    try:
        cmd = ["vnstat", "-i", INTERFACE] + args
        return subprocess.check_output(cmd, text=True)
    except subprocess.CalledProcessError:
        return ""

def parse_line(output, search_term, indices):
    """Filters lines and extracts specific columns manually."""
    for line in output.splitlines():
        if search_term in line.lower():
            parts = line.split()
            try:
                return f"{parts[indices[0]]} {parts[indices[1]]}"
            except IndexError:
                continue
    return "N/A"

def to_gb(stat_string):
    """Converts a vnStat string (e.g. '330.61 MiB') to a float in GB."""
    try:
        value, unit = stat_string.split()
        val = float(value)
        unit = unit.lower()
        if "mib" in unit:
            return val / 1024
        if "tib" in unit:
            return val * 1024
        return val # Default for GiB/GB
    except:
        return 0.0

def main():
    # Fetching Day and Month separately to avoid flag override
    day_data = get_vnstat_output(["--days", "2"])
    month_data = get_vnstat_output(["--months", "1"])

    # Extracting values
    yesterday_date = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
    yesterday = parse_line(day_data, yesterday_date, (4, 5))

    current_month = datetime.now().strftime("%Y-%m")
    month_total = parse_line(month_data, current_month, (4, 5))

    estimate = parse_line(month_data, "estimated", (4, 5))

    current_gb = to_gb(month_total)
    percentage = (current_gb / LIMIT_GB) * 100

    # Constructing the Message using
    report_msg = (
        f"📊 *DAILY BANDWIDTH REPORT* 📊\n\n"
        f"🗓️ *Yesterday's usage:* {yesterday}\n"
        f"(Data sent from VM to users)\n\n"
        f"📅 *Monthly total (TX):* {month_total} ({percentage:.2f}%)\n"
        f"Progress towards {LIMIT_GB}GB limit.\n\n"
        f"📈 *Estimated end of month:* {estimate}\n\n"
        f"_Source: vnStat Monitoring_"
    )

    # 4. Sending to Telegram via Requests
    url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
    payload = {
        "chat_id": ID,
        "message_thread_id": THREAD_ID,
        "text": report_msg,
        "parse_mode": "Markdown"
    }

    try:
        response = requests.post(url, data=payload)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Error sending report: {e}")

if __name__ == "__main__":
    main()
