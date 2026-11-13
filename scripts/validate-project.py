#!/usr/bin/env python3
"""Static guardrails for changes to the Brave Origin Docker package."""
from pathlib import Path
import xml.etree.ElementTree as ET
from collections import Counter

root = Path(__file__).resolve().parents[1]
template = ET.parse(root / 'unraid' / 'brave-org.xml').getroot()
configs = template.findall('Config')
variables = [c.attrib['Target'] for c in configs if c.attrib.get('Type') == 'Variable']
duplicates = sorted(k for k, v in Counter(variables).items() if v > 1)
assert not duplicates, f'Duplicate Unraid environment variable targets: {duplicates}'
assert variables.count('TITLE') == 1, 'Expected exactly one TITLE variable'
assert 'SELKIES_UI_TITLE' not in variables, 'SELKIES_UI_TITLE overrides TITLE; omit it to keep one tab-title control'
assert variables.count('CUSTOM_USER') == 1
assert variables.count('PASSWORD') == 1
assert (root / 'Dockerfile').read_text().count('SELKIES_UI_TITLE') == 0
assert 'seccomp=unconfined --shm-size=1g' in (root/'unraid'/'brave-org.xml').read_text()
assert 'ghcr.io/mspdaniel/brave-org:latest' in (root/'compose.yml').read_text()
assert '/mnt/user/appdata/brave-org:/config' in (root/'compose.yml').read_text()
assert (root / '.github' / 'workflows' / 'docker-image.yml').is_file()
print('OK: unique Unraid variables, title, authentication, persistent volume, security options, and workflow paths')

launcher=(root / 'root/usr/local/bin/start-brave-org').read_text()
assert 'while (( ! STOPPING ))' in launcher
assert 'wait "$BRAVE_PID"' in launcher
assert 'sleep 3 &' in launcher
assert '--user-data-dir=/config/brave-org-profile' in launcher
assert (root / 'root/defaults/autostart').read_text().count('start-brave-org') == 1
assert (root / 'root/defaults/autostart_wayland').read_text().count('start-brave-org') == 1
print('OK: supervised Brave launcher, original profile/flags, and single desktop autostart')

# Validate the optional X11 taskbar integration.
config=(root/'root/usr/local/share/brave-org/tint2rc').read_text()
assert 'panel_items = T' in config and 'strut_policy = follow_size' in config
assert 'tint2 -c /usr/local/share/brave-org/tint2rc' in launcher
assert 'TASKBAR_PID=$!' in launcher
assert 'fonts-noto-core tint2;' in (root/'Dockerfile').read_text()
print('OK: tint2 is installed, launched once from Openbox, and not tied to Brave restarts')
