"""Fügt Übersetzungen (de-Schlüssel → en) in Shared/Localizable.xcstrings ein, ohne die Reihenfolge zu ändern.
Aufruf: python3 Tools/add_strings.py '{"Deutsch": "English", ...}'"""
import json, sys
p = 'Shared/Localizable.xcstrings'
raw = open(p).read()
d = json.loads(raw)
for k, v in json.loads(sys.argv[1]).items():
    d['strings'][k] = {"localizations": {"en": {"stringUnit": {"state": "translated", "value": v}}}}
open(p, 'w').write(json.dumps(d, ensure_ascii=False, indent=2, separators=(',', ' : ')) + ("\n" if raw.endswith("\n") else ""))
