#!/bin/zsh
# Hörproben der Ton-Sets aus dem echten App-Code rendern, ohne Simulator und ohne Gerät.
#
# Wozu: Klang lässt sich im Simulator nicht prüfen, und wer am Klang arbeitet, hört ihn vielleicht gar nicht selbst.
# Darum: Töne rendern, Messwerte lesen, die Dateien Philippe schicken und ihn wählen lassen.
#
#   Tools/hoerprobe.sh                    alle Ton-Sets nach build/hoerprobe/<set>.m4a
#   HALL="0.5 1.5" Tools/hoerprobe.sh     dazu die Glocke mit anderem Hall-Anteil (chime-hall-0.5.m4a …)
#
# Jede Datei spielt: 3-2-1 und Start einer Übung, 3-2-1 und Start einer Pause, Halbzeit, Schluss.
# Die Tonerzeugung steht in FitMitJodit/Run/AudioSignalPlayer.swift (enum ToneSynth).
set -e
cd "$(dirname "$0")/.."
OUT=build/hoerprobe
TMP=$(mktemp -d)
mkdir -p "$OUT"

# Die Typen der App herauslösen (jeweils von der Deklaration bis zur schliessenden Klammer in Spalte 1).
{
  echo "import AVFoundation"
  sed -n '/^enum BlockKind/,/^}/p' Shared/Model/Workout.swift
  sed -n '/^enum SignalKind/,/^}/p' Shared/Timer/SignalPlan.swift
  sed -n '/^enum ToneSet/,/^}/p' Shared/Timer/SignalPlan.swift
  sed -n '/^enum ToneSynth/,/^}/p' FitMitJodit/Run/AudioSignalPlayer.swift
} > "$TMP/app.swift"

# $1 = Hall-Anteil der Glocke (leer: wie in der App), $2 = Namenszusatz, $3 = nur dieses Ton-Set
render() {
  cp "$TMP/app.swift" "$TMP/all.swift"
  if [ -n "$1" ]; then
    sed -i '' -E "s/static let chimeHall = [0-9.]+/static let chimeHall = $1/" "$TMP/all.swift"
  fi
  cat Tools/hoerprobe/main.swift >> "$TMP/all.swift"
  swiftc -O -o "$TMP/render" "$TMP/all.swift"
  "$TMP/render" "$OUT" $2 $3
}

render
for hall in ${=HALL}; do
  render "$hall" "-hall-$hall" chime
done

for wav in "$OUT"/*.wav; do
  afconvert -f m4af -d aac -b 128000 "$wav" "${wav%.wav}.m4a"
  rm "$wav"
done
rm -rf "$TMP"
echo "Hörproben unter $OUT:"
ls "$OUT"
