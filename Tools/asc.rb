# Kleiner App-Store-Connect-Client (nur Ruby-Standardbibliothek).
# Nutzung: ruby Tools/asc.rb GET /v1/apps   |  ruby Tools/asc.rb POST /v1/betaGroups '{json}'
# Liest ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH aus fastlane/.env.
require 'openssl'; require 'json'; require 'base64'; require 'net/http'
env = File.read(File.expand_path('../fastlane/.env', __dir__)).lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }.to_h { |l| l.split('=', 2) }
key = OpenSSL::PKey::EC.new(File.read(env['ASC_KEY_PATH']))
b64 = ->(s) { Base64.urlsafe_encode64(s).delete('=') }
h = b64.({ alg: 'ES256', kid: env['ASC_KEY_ID'], typ: 'JWT' }.to_json); now = Time.now.to_i
pl = b64.({ iss: env['ASC_ISSUER_ID'], iat: now, exp: now + 900, aud: 'appstoreconnect-v1' }.to_json)
der = key.sign(OpenSSL::Digest::SHA256.new, "#{h}.#{pl}")
sig = OpenSSL::ASN1.decode(der).value.map { |v| v.value.to_s(2).rjust(32, "\0") }.join
jwt = "#{h}.#{pl}.#{b64.(sig)}"
meth, path, body = ARGV
uri = URI("https://api.appstoreconnect.apple.com#{path}")
req = { 'GET' => Net::HTTP::Get, 'POST' => Net::HTTP::Post, 'PATCH' => Net::HTTP::Patch }.fetch(meth).new(uri)
req['Authorization'] = "Bearer #{jwt}"; req['Content-Type'] = 'application/json'
req.body = body if body
res = Net::HTTP.start(uri.host, 443, use_ssl: true) { |x| x.request(req) }
puts res.code
puts res.body
