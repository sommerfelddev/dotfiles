#!/usr/bin/env dash
# Emit waybar JSON with memory usage. Used% uses a heat scale (green → red),
# available% uses the inverse (red → green). Values embedded via Pango span.
set -eu

awk '
function heat(p) {
	if (p < 30) return "#b8bb26"
	if (p < 60) return "#fabd2f"
	if (p < 80) return "#fe8019"
	return "#fb4934"
}
/^MemTotal:/     { t = $2 }
/^MemAvailable:/ { a = $2 }
END {
	u  = t - a
	up = u * 100 / t
	printf "{\"text\":\"MEM %.1fG <span color=\x27%s\x27>%d%%</span>\"}\n", \
		u / 1048576, heat(up), up
}
' /proc/meminfo
