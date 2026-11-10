# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
# Liest die Store-Texte aus App Store Connect und vergleicht mit fastlane/metadata.
require 'json'
def api(path) = JSON.parse(`ruby #{__dir__}/asc.rb GET '#{path}'`.lines[1..].join)
app = '6833153713'
v = api("/v1/apps/#{app}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION")['data'][0]
locs = api("/v1/appStoreVersions/#{v['id']}/appStoreVersionLocalizations")['data']
info = api("/v1/apps/#{app}/appInfos")['data'].find { |i| i['attributes']['appStoreState'] != 'READY_FOR_SALE' } || api("/v1/apps/#{app}/appInfos")['data'][0]
ilocs = api("/v1/appInfos/#{info['id']}/appInfoLocalizations")['data']
md = File.expand_path('../fastlane/metadata', __dir__)
ok = true
check = lambda do |loc, field, remote|
  f = File.join(md, loc, "#{field}.txt")
  next unless File.exist?(f)
  local = File.read(f).strip
  same = local == remote.to_s.strip
  ok &&= same
  puts "#{same ? 'gleich ' : 'ANDERS '} #{loc} #{field}"
end
locs.each do |l|
  a = l['attributes']; loc = a['locale']
  { 'description' => 'description', 'keywords' => 'keywords', 'promotional_text' => 'promotionalText',
    'support_url' => 'supportUrl', 'marketing_url' => 'marketingUrl' }.each { |f, k| check.(loc, f, a[k]) }
end
ilocs.each do |l|
  a = l['attributes']; loc = a['locale']
  { 'name' => 'name', 'subtitle' => 'subtitle', 'privacy_url' => 'privacyPolicyUrl' }.each { |f, k| check.(loc, f, a[k]) }
end
puts "copyright: #{v['attributes']['copyright']}"
puts ok ? 'ERGEBNIS: alles gleich' : 'ERGEBNIS: Abweichungen'
