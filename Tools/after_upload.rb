# Nach `fastlane ios beta`: Testtexte (de-DE, en-US) setzen, Build der externen Gruppe zuweisen und zur
# Beta-Prüfung einreichen. Die interne Gruppe «Intern» bekommt jeden Build von selbst.
#
# Aufruf:  LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 ruby Tools/after_upload.rb [--dry]
#   --dry  zeigt nur, was geschehen würde, und ändert nichts.
#
# Die Beta-Prüfung ist nur für externe Tester nötig und ist NICHT die Prüfung für den App Store. Trotzdem nur
# ausführen, wenn Philippe den Upload «in beide Gruppen» verlangt hat (CLAUDE.md, Regel 5).
# Mehrfach ausführen schadet nicht: Was schon steht, wird übersprungen.
require 'json'
Dir.chdir(File.expand_path('..', __dir__))
DRY = ARGV.include?('--dry')
BUNDLE_ID = 'ch.fitmitjodit.timer'
EXTERNAL_GROUP = 'Jodit'
TEXTS = { 'de-DE' => 'fastlane/testflight/whats_new-de-DE.txt', 'en-US' => 'fastlane/testflight/whats_new-en-US.txt' }

# `Tools/asc.rb` gibt zuerst den Statuscode aus, dann den JSON-Text.
def asc(meth, path, body = nil)
  args = ['ruby', 'Tools/asc.rb', meth, path]
  args << JSON.generate(body) if body
  out = IO.popen(args, external_encoding: 'UTF-8', &:read)
  code, json = out.split("\n", 2)
  [code.to_i, (json.nil? || json.strip.empty?) ? {} : JSON.parse(json)]
end

def problem(res) = res['errors']&.first&.dig('detail')

number = File.read('Config/Version.xcconfig', encoding: 'UTF-8')[/APP_BUILD_NUMBER = (\d+)/, 1]
_, apps = asc('GET', "/v1/apps?filter[bundleId]=#{BUNDLE_ID}&fields[apps]=bundleId")
app = apps['data'].first['id']
_, builds = asc('GET', "/v1/builds?filter[app]=#{app}&filter[version]=#{number}&fields[builds]=version,processingState,usesNonExemptEncryption")
abort "Build #{number} nicht gefunden (noch nicht hochgeladen oder noch in Verarbeitung?)" if builds['data'].empty?
build = builds['data'].first
id = build['id']
puts "Build #{number}: #{id}, #{build['attributes']['processingState']}, Verschlüsselung #{build['attributes']['usesNonExemptEncryption'].inspect}"

_, detail = asc('GET', "/v1/builds/#{id}/buildBetaDetail")
puts "intern: #{detail.dig('data', 'attributes', 'internalBuildState')}, extern: #{detail.dig('data', 'attributes', 'externalBuildState')}"

# 1. Testtexte («Was zu testen ist»), höchstens 4000 Zeichen
_, locs = asc('GET', "/v1/builds/#{id}/betaBuildLocalizations")
TEXTS.each do |locale, file|
  text = File.read(file, encoding: 'UTF-8').strip
  abort "#{locale}: Text zu lang (#{text.length} von höchstens 4000 Zeichen)" if text.length > 4000
  existing = locs['data'].find { |l| l['attributes']['locale'] == locale }
  if existing && existing['attributes']['whatsNew'].to_s.strip == text
    puts "#{locale}: Text steht schon (#{text.length} Zeichen)"
  elsif DRY
    puts "#{locale}: würde gesetzt (#{text.length} Zeichen, #{existing ? 'PATCH' : 'POST'})"
  elsif existing
    code, res = asc('PATCH', "/v1/betaBuildLocalizations/#{existing['id']}", { data: { type: 'betaBuildLocalizations', id: existing['id'], attributes: { whatsNew: text } } })
    puts "#{locale}: PATCH #{code} #{problem(res)}"
  else
    code, res = asc('POST', '/v1/betaBuildLocalizations', { data: { type: 'betaBuildLocalizations', attributes: { locale: locale, whatsNew: text }, relationships: { build: { data: { type: 'builds', id: id } } } } })
    puts "#{locale}: POST #{code} #{problem(res)}"
  end
end

# 2. Externe Gruppe. Von der Gruppe her lesen: `GET /v1/builds/{id}/betaGroups` erlaubt die API nicht (403),
#    und `sort` kennt dieser Aufruf auch nicht.
_, groups = asc('GET', "/v1/betaGroups?filter[app]=#{app}&filter[name]=#{EXTERNAL_GROUP}&fields[betaGroups]=name,isInternalGroup")
group = groups['data']&.first
abort "Gruppe «#{EXTERNAL_GROUP}» nicht gefunden" unless group
_, members = asc('GET', "/v1/betaGroups/#{group['id']}/builds?fields[builds]=version&limit=200")
if (members['data'] || []).any? { |b| b['id'] == id }
  puts "Gruppe «#{EXTERNAL_GROUP}»: Build ist schon zugewiesen"
elsif DRY
  puts "Gruppe «#{EXTERNAL_GROUP}»: würde zugewiesen"
else
  code, res = asc('POST', "/v1/betaGroups/#{group['id']}/relationships/builds", { data: [{ type: 'builds', id: id }] })
  puts "Gruppe «#{EXTERNAL_GROUP}» zugewiesen: #{code} #{problem(res)}"
end

# 3. Beta-Prüfung (nur für externe Tester). Folgebuilds derselben Version gibt Apple meist innert Minuten frei.
_, sub = asc('GET', "/v1/builds/#{id}/betaAppReviewSubmission")
state = sub.dig('data', 'attributes', 'betaReviewState')
if state
  puts "Beta-Prüfung: #{state}"
elsif DRY
  puts 'Beta-Prüfung: würde eingereicht'
else
  code, res = asc('POST', '/v1/betaAppReviewSubmissions', { data: { type: 'betaAppReviewSubmissions', relationships: { build: { data: { type: 'builds', id: id } } } } })
  puts "Beta-Prüfung eingereicht: #{code} #{res.dig('data', 'attributes', 'betaReviewState')} #{problem(res)}"
end
puts "BUILD_ID=#{id}"
