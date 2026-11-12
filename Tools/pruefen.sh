#!/bin/zsh
# Prüflauf: baut und testet nacheinander (nie parallel) und meldet je Schritt eine Zeile.
#
#   Tools/pruefen.sh                       schnell: Unit-Tests iPhone und iPad 11 Zoll, Watch-Build (rund 4 Minuten)
#   Tools/pruefen.sh voll                  alles: Unit- und UI-Tests auf iPhone, iPad 11, iPad 13 und Duo, Watch-Tests
#                                          (rund 1.5 Stunden, die UI-Tests brauchen 17 bis 40 Minuten je Gerät)
#   Tools/pruefen.sh unit:iphone ui:ipad11 watch-build watch-tests     einzelne Schritte in dieser Reihenfolge
#
# Vor jedem Commit mindestens «schnell», nach Änderungen an Bedienung oder Layout die UI-Tests der betroffenen
# Geräte, vor einem Upload nach grösseren Änderungen «voll». Die Logs liegen unter build/logs/pruefen-*.log.
#
# Die UDIDs gelten für Philippes Mac. Auf einem anderen Mac: `xcrun simctl list devices` und hier anpassen oder
# die Variablen FMJ_IPHONE, FMJ_IPAD11, FMJ_IPAD13, FMJ_DUO, FMJ_WATCH setzen.
cd "$(dirname "$0")/.."
typeset -A DEVICE
DEVICE=(
  iphone ${FMJ_IPHONE:-B4A2B008-6287-41D2-A41C-4D700BDFD6AC}
  ipad11 ${FMJ_IPAD11:-9E8A5E38-0E9B-443D-B5EF-7F76E08997EB}
  ipad13 ${FMJ_IPAD13:-C9B3BAD3-B150-4014-A87E-711D35799E4C}
  duo    ${FMJ_DUO:-DFA3DA79-4E7B-43EE-BBB4-EC32549F3781}
)
WATCH=${FMJ_WATCH:-5379D419-6843-4225-8139-0EA0EF101E61}
APP=ch.fitmitjodit.timer
LOGS=build/logs
mkdir -p $LOGS
FAILED=0

summary() { grep -E 'Executed [0-9]+ tests' "$1" | tail -1 | sed 's/^[[:space:]]*//' }

# Tests auf einem iOS-Simulator. $1 = Schritt (unit|ui), $2 = Gerät.
# Unit-Tests laufen über das Schema FitMitJoditUnit, UI-Tests einzeln über FitMitJodit. Im Gesamtschema startet der
# Unit-Teil manchmal nicht: Der Kurzbefehl-Dienst des Simulators (`linkd`) startet die App selbst und kommt
# xcodebuild zuvor («test runner hung before establishing connection», «failed to launch»). Darum die App vorher
# beenden und einen solchen Lauf einmal wiederholen. Ein Lauf zählt erst, wenn «Executed N tests» dasteht.
ios_tests() {
  local step=$1 name=$2 udid=${DEVICE[$2]} log=$LOGS/pruefen-$1-$2.log
  [ -z "$udid" ] && { echo "$step $name: unbekanntes Gerät"; FAILED=1; return }
  local -a what
  if [ $step = unit ]; then what=(-scheme FitMitJoditUnit); else what=(-scheme FitMitJodit -only-testing:FitMitJoditUITests); fi
  xcrun simctl boot $udid 2>/dev/null
  local try code
  for try in 1 2; do
    xcrun simctl terminate $udid $APP 2>/dev/null
    xcodebuild test -project FitMitJodit.xcodeproj $what -destination "platform=iOS Simulator,id=$udid" \
      -derivedDataPath build/DerivedData -parallel-testing-enabled NO > $log 2>&1
    code=$?
    [ -n "$(summary $log)" ] && break
    echo "$step $name: Testlauf nicht gestartet, Versuch $try"
  done
  [ $code -ne 0 ] && FAILED=1
  echo "$step $name: exit=$code $(summary $log)"
  [ $code -ne 0 ] && grep -E "error:|XCTAssert|failed \(" $log | grep -v "CloudKit\|AppShortcut" | head -8
}

watch_step() {
  local action=$1 log=$LOGS/pruefen-watch-$1.log
  if [ $action = build ]; then
    xcodebuild build -project FitMitJodit.xcodeproj -scheme FitMitJoditWatch -destination "platform=watchOS Simulator,id=$WATCH" \
      -derivedDataPath build/DerivedData -quiet > $log 2>&1
  else
    xcodebuild test -project FitMitJodit.xcodeproj -scheme FitMitJoditWatch -destination "platform=watchOS Simulator,id=$WATCH" \
      -derivedDataPath build/DerivedData -parallel-testing-enabled NO > $log 2>&1
  fi
  local code=$?
  [ $code -ne 0 ] && FAILED=1
  echo "watch-$action: exit=$code $(summary $log)"
  [ $code -ne 0 ] && grep -E "error:|XCTAssert|failed \(" $log | head -8
}

case "${1:-schnell}" in
  schnell) STEPS=(unit:iphone unit:ipad11 watch-build) ;;
  voll)    STEPS=(unit:iphone unit:ipad11 unit:ipad13 unit:duo ui:iphone ui:ipad11 ui:ipad13 ui:duo watch-tests) ;;
  *)       STEPS=("$@") ;;
esac

for s in $STEPS; do
  case $s in
    unit:*|ui:*)  ios_tests ${s%%:*} ${s#*:} ;;
    watch-build)  watch_step build ;;
    watch-tests)  watch_step tests ;;
    *)            echo "Unbekannter Schritt: $s"; FAILED=1 ;;
  esac
done
[ $FAILED -eq 0 ] && echo "Prüflauf grün" || echo "Prüflauf mit Fehlern"
exit $FAILED
