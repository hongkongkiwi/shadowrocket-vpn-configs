#!/usr/bin/env ruby

require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILT_INS = %w[DIRECT REJECT PROXY direct reject proxy].freeze
errors = []

def lines(path)
  File.readlines(File.join(ROOT, path), chomp: true)
end

def section(path, name)
  active = false
  lines(path).each_with_object([]) do |line, result|
    if line == "[#{name}]"
      active = true
      next
    end
    if line.start_with?("[")
      active = false
      next
    end
    result << line if active
  end
end

def entries(path, name)
  section(path, name).reject { |line| line.empty? || line.start_with?("#", ";", "//") }
end

def groups(path)
  entries(path, "Proxy Group").map { |line| line.split("=", 2).first.strip }
end

def rule_policy(line)
  fields = line.split(",").map(&:strip)
  case fields.first.upcase
  when "FINAL", "MATCH" then fields[1]
  else fields[2]
  end
end

def precedes?(body, first, second)
  first_index = body.index(first)
  second_index = body.index(second)
  first_index && second_index && first_index < second_index
end

def check_policy_refs(path, known, errors)
  entries(path, "Rule").each do |line|
    policy = rule_policy(line)
    next if known.include?(policy)

    errors << "#{path}: unresolved policy #{policy.inspect} in #{line.inspect}"
  end
end

base_groups = groups("shadowrocket.conf")
check_policy_refs("shadowrocket.conf", base_groups + BUILT_INS, errors)
check_policy_refs("exports/surge/Surge.conf", groups("exports/surge/Surge.conf") + BUILT_INS, errors)

Dir.glob(File.join(ROOT, "modules/*.module")).sort.each do |absolute|
  path = absolute.delete_prefix("#{ROOT}/")
  check_policy_refs(path, base_groups + groups(path) + BUILT_INS, errors)
end

clash = YAML.safe_load(File.read(File.join(ROOT, "exports/clash/config.yaml")), aliases: false)
clash_groups = clash.fetch("proxy-groups").map { |group| group.fetch("name") }
clash_providers = clash.fetch("rule-providers").keys

clash.fetch("proxy-groups").each do |group|
  group.fetch("proxies", []).each do |policy|
    next if (clash_groups + BUILT_INS).include?(policy)

    errors << "exports/clash/config.yaml: #{group.fetch("name")} references unknown group #{policy.inspect}"
  end
end

clash.fetch("rules").each do |rule|
  fields = rule.split(",").map(&:strip)
  if fields.first == "RULE-SET"
    errors << "exports/clash/config.yaml: unknown provider #{fields[1].inspect}" unless clash_providers.include?(fields[1])
    policy = fields[2]
  else
    policy = fields.first == "MATCH" ? fields[1] : fields[2]
  end
  errors << "exports/clash/config.yaml: unknown policy #{policy.inspect}" unless (clash_groups + BUILT_INS).include?(policy)
end

errors << "exports/clash/config.yaml: VPSDance must use YAML format" unless clash.dig("rule-providers", "ai-vpsdance", "format") == "yaml"
errors << "exports/clash/config.yaml: DNS must bind to localhost" unless clash.dig("dns", "listen") == "127.0.0.1:1053"
errors << "exports/clash/config.yaml: DNS bootstrap resolvers are missing" if clash.dig("dns", "default-nameserver").to_a.empty?

qx_path = "exports/quantumultx/QuantumultX.conf"
qx = lines(qx_path)
qx_policies = entries(qx_path, "policy").each_with_object([]) do |line, policies|
  next unless line.start_with?("static=", "url-latency-benchmark=")

  policies << line.split("=", 2)[1].split(",", 2).first.strip
end

entries(qx_path, "filter_remote").each do |line|
  force = line[/force-policy=([^,]+)/, 1]&.strip
  tag = line[/tag=([^,]+)/, 1]&.strip
  policy = force || tag
  errors << "#{qx_path}: remote filter has no resolvable policy in #{line.inspect}" unless (qx_policies + BUILT_INS).include?(policy)
end

entries(qx_path, "filter_local").each do |line|
  policy = rule_policy(line)
  errors << "#{qx_path}: unknown local policy #{policy.inspect}" unless (qx_policies + BUILT_INS).include?(policy)
end

errors << "#{qx_path}: old url-test policy syntax remains" if qx.any? { |line| line.start_with?("url-test=") }
errors << "#{qx_path}: OneDrive policy is missing" unless qx_policies.include?("OneDrive")
errors << "#{qx_path}: PrimeVideo policy is missing" unless qx_policies.include?("PrimeVideo")
errors << "#{qx_path}: Apple Account policy is missing" unless qx_policies.include?("Apple Account")
errors << "#{qx_path}: DoH is not enabled" unless qx.any? { |line| line.start_with?("doh-server = https://") }
errors << "#{qx_path}: Apple Account authentication rule is missing" unless qx.include?("host, account.apple.com, Apple Account")
errors << "#{qx_path}: Apple certificate checks must stay direct" unless qx.include?("host, ocsp.digicert.com, direct")

all_config = (["shadowrocket.conf"] + Dir.glob(File.join(ROOT, "modules/*.module")).map { |path| path.delete_prefix("#{ROOT}/") } + %w[exports/clash/config.yaml exports/surge/Surge.conf exports/quantumultx/QuantumultX.conf]).to_h { |path| [path, File.read(File.join(ROOT, path))] }
banned = ["Apple-Push.list", "/Advertising/Privacy.list", "/Forbidden/Forbidden.list", "sr_ad_only.conf", "carrnot/china-ip-list", "🇨🇳 Taiwan Node"]
banned.each do |text|
  all_config.each { |path, body| errors << "#{path}: contains retired text #{text.inspect}" if body.include?(text) }
end

main = all_config.fetch("shadowrocket.conf")
errors << "shadowrocket.conf: Apple routing must stay in its module" if main.include?("🍎 Apple Services")
errors << "shadowrocket.conf: Reject must precede broad AI rules" unless precedes?(main, "Rules/Reject.list", "ai-proxy-rules")
expected_skip_proxy = "skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 127.0.0.1, localhost, *.local, captive.apple.com"
skip_proxy_lines = main.lines.map(&:strip).grep(/^skip-proxy\s*=/)
errors << "shadowrocket.conf: skip-proxy must contain local access only" unless skip_proxy_lines == [expected_skip_proxy]
errors << "shadowrocket.conf: QUIC blocking must stay in the base profile" unless main.include?("block-quic = all-proxy")

privacy_dns = all_config.fetch("modules/privacy-dns.module")
privacy_dns_settings = {
  "dns-server" => "https://cloudflare-dns.com/dns-query",
  "fallback-dns-server" => "https://dns.quad9.net/dns-query",
  "dns-direct-system" => "false",
  "dns-direct-fallback-proxy" => "false",
  "hijack-dns" => "*:53"
}
privacy_dns_settings.each do |setting, value|
  errors << "modules/privacy-dns.module: invalid #{setting}" unless privacy_dns.lines.map(&:strip).include?("#{setting} = #{value}")
  errors << "shadowrocket.conf: #{setting} must stay in the privacy DNS module" if main.match?(/^#{Regexp.escape(setting)}\s*=/)
end

china_dns = all_config.fetch("modules/dns-mainland-china.module")
china_dns_settings = {
  "dns-server" => "https://dns.alidns.com/dns-query#no-h3",
  "fallback-dns-server" => "https://doh.pub/dns-query#no-h3",
  "dns-direct-system" => "false",
  "dns-direct-fallback-proxy" => "false",
  "hijack-dns" => "*:53"
}
china_dns_settings.each do |setting, value|
  errors << "modules/dns-mainland-china.module: invalid #{setting}" unless china_dns.lines.map(&:strip).include?("#{setting} = #{value}")
end

private_ip = all_config.fetch("modules/private-ip-block.module")
errors << "modules/private-ip-block.module: private DNS answers must be rejected" unless private_ip.include?("private-ip-answer = false")
errors << "shadowrocket.conf: private-ip-answer must stay in its module" if main.match?(/^private-ip-answer\s*=/)

real_ip = all_config.fetch("modules/real-ip-compat.module")
errors << "modules/real-ip-compat.module: always-real-ip is missing" unless real_ip.match?(/^always-real-ip\s*=/)
errors << "shadowrocket.conf: always-real-ip must stay in its module" if main.match?(/^always-real-ip\s*=/)
errors << "modules/real-ip-compat.module: Apple exceptions belong in the Apple module" if real_ip.match?(/apple|icloud|cp4\.cloudflare/i)

apple = all_config.fetch("modules/apple-services.module")
errors << "modules/apple-services.module: AppleCN source is missing" unless apple.include?("Rules/AppleCN.list")
errors << "modules/apple-services.module: AppleServers source is missing" unless apple.include?("Rules/AppleServers.list")
errors << "modules/apple-services.module: narrow Apple rules must stay in separate modules" if apple.match?(/^(?:DOMAIN(?:-SUFFIX|-KEYWORD|-WILDCARD)?|IP-CIDR6?),/)
errors << "modules/apple-services.module: App Store host override must stay separate" if apple.include?("iosapps.itunes.apple.com =")

apple_account = all_config.fetch("modules/apple-account.module")
%w[account.apple.com appleid.cdn-apple.com idmsa.apple.com gsa.apple.com setup.icloud.com].each do |domain|
  errors << "modules/apple-account.module: missing #{domain}" unless apple_account.include?(domain)
end

apple_certificates = all_config.fetch("modules/apple-certificate-validation.module")
%w[certs.apple.com crl.apple.com crl3.digicert.com crl4.digicert.com ocsp.apple.com ocsp.digicert.cn ocsp.digicert.com ocsp2.apple.com valid.apple.com appattest.apple.com].each do |domain|
  errors << "modules/apple-certificate-validation.module: missing #{domain}" unless apple_certificates.include?(domain)
end
errors << "modules/apple-certificate-validation.module: certificate checks must stay direct" if entries("modules/apple-certificate-validation.module", "Rule").any? { |line| rule_policy(line) != "DIRECT" }

apple_push = all_config.fetch("modules/apple-push.module")
%w[push.apple.com push-apple.com.akadns.net].each do |domain|
  errors << "modules/apple-push.module: missing #{domain}" unless apple_push.include?(domain)
end

apple_updates = all_config.fetch("modules/apple-updates.module")
%w[gateway.icloud.com gdmf.apple.com swscan.apple.com updates.cdn-apple.com].each do |domain|
  errors << "modules/apple-updates.module: missing #{domain}" unless apple_updates.include?(domain)
end

apple_intelligence = all_config.fetch("modules/apple-intelligence.module")
%w[guzzoni.apple.com smoot.apple.com apple-relay.cloudflare.com apple-relay.fastly-edge.com cp4.cloudflare.com apple-relay.apple.com].each do |domain|
  errors << "modules/apple-intelligence.module: missing #{domain}" unless apple_intelligence.include?(domain)
end

apple_cdn = all_config.fetch("modules/apple-app-store-cdn.module")
errors << "modules/apple-app-store-cdn.module: Kingsoft host override is missing" unless apple_cdn.include?("iosapps.itunes.apple.com = iosapps.itunes.apple.com.download.ks-cdn.com")

%w[gateway.icloud.com apple-relay.cloudflare.com cp4.cloudflare.com apple-relay.fastly-edge.com gdmf.apple.com swscan.apple.com sequoia.siri.apple.com sequoia.apple.com iosapps.itunes.apple.com account.apple.com idmsa.apple.com gsa.apple.com].each do |domain|
  errors << "shadowrocket.conf: #{domain} must stay in the Apple module" if main.include?(domain)
end

china_compat = all_config.fetch("modules/china-app-tun-compat.module")
errors << "modules/china-app-tun-compat.module: extended skip-proxy list is missing" unless china_compat.include?("passenger.t3go.cn") && china_compat.include?(expected_skip_proxy.delete_prefix("skip-proxy = "))

ipv6 = all_config.fetch("modules/ipv6.module")
errors << "modules/ipv6.module: IPv6 settings are incomplete" unless ipv6.include?("ipv6 = true") && ipv6.include?("prefer-ipv6 = true")

readme = File.read(File.join(ROOT, "README.md"))
Dir.glob(File.join(ROOT, "modules/*.module")).sort.each do |absolute|
  filename = File.basename(absolute)
  raw_url = "https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/#{filename}"
  cdn_url = "https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/#{filename}"
  errors << "README.md: missing raw URL for #{filename}" unless readme.include?(raw_url)
  errors << "README.md: missing jsDelivr URL for #{filename}" unless readme.include?(cdn_url)
end

surge = all_config.fetch("exports/surge/Surge.conf")
errors << "exports/surge/Surge.conf: Reject must precede broad AI rules" unless precedes?(surge, "Rules/Reject.list", "ai-proxy-rules")
errors << "exports/surge/Surge.conf: Apple Account must precede broad Apple lists" unless precedes?(surge, "account.apple.com,🔐 Apple Account", "rule/Surge/Apple/Apple.list")
errors << "exports/surge/Surge.conf: Apple service overrides must use the selectable group" unless surge.include?("gateway.icloud.com,🍎 Apple Services")
errors << "exports/surge/Surge.conf: App Store CDN override must remain optional" if surge.include?("iosapps.itunes.apple.com =")

clash_rules = clash.fetch("rules")
errors << "exports/clash/config.yaml: ads must precede broad AI rules" unless clash_rules.index("RULE-SET,ads,REJECT") < clash_rules.index("RULE-SET,ai-vpsdance,🤖 AI")
errors << "exports/clash/config.yaml: Apple Account must precede broad Apple lists" unless clash_rules.index("DOMAIN,account.apple.com,🔐 Apple Account") < clash_rules.index("RULE-SET,apple,🍎 Apple Services")
errors << "exports/clash/config.yaml: Apple service overrides must use the selectable group" unless clash_rules.include?("DOMAIN-SUFFIX,gateway.icloud.com,🍎 Apple Services")

errors << "#{qx_path}: ad filters must precede AI filters" unless precedes?(all_config.fetch(qx_path), "/Advertising/Advertising.list", "/OpenAI/OpenAI.list")
errors << "#{qx_path}: excluded routes need CIDR masks" unless all_config.fetch(qx_path).include?("excluded_routes = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 127.0.0.0/8, 100.64.0.0/10")

if errors.empty?
  puts "All config checks passed."
else
  warn errors.join("\n")
  exit 1
end
