#!/bin/sh
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
function cool(p) {
	if (p < 20) return "#fb4934"
	if (p < 40) return "#fe8019"
	if (p < 70) return "#fabd2f"
	return "#b8bb26"
}
/^MemTotal:/     { t = $2 }
/^MemAvailable:/ { a = $2 }
END {
	u  = t - a
	up = u * 100 / t
	ap = a * 100 / t
	printf "{\"text\":\"MEM %.1fG (<span color=\x27%s\x27>%d%%</span>) / %.1fG (<span color=\x27%s\x27>%d%%</span>)\"}\n", \
		u / 1048576, heat(up), up, \
		a / 1048576, cool(ap), ap
}
' /proc/meminfo
