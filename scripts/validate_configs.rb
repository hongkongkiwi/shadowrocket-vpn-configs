#!/usr/bin/env ruby

require "yaml"
require "uri"

ROOT = File.expand_path("..", __dir__)
BUILT_INS = %w[DIRECT REJECT PROXY direct reject proxy].freeze
BASE = "shadowrocket.conf"
SURGE = "exports/surge/Surge.conf"
CLASH = "exports/clash/config.yaml"
QX = "exports/quantumultx/QuantumultX.conf"
MODULE_CONFLICTS = [
  %w[adblock-core adblock-lite],
  %w[privacy-dns dns-mainland-china],
  %w[security-dns privacy-dns],
  %w[security-dns dns-mainland-china],
  %w[back-to-cn back-to-cn-all],
  %w[ipv6 ipv6-preferred]
].freeze
NEW_AI_CASES = {
  "api.githubcopilot.com" => "🧑‍💻 GitHub Copilot",
  "copilot-proxy.githubusercontent.com" => "🧑‍💻 GitHub Copilot",
  "copilot.microsoft.com" => "🪟 Microsoft Copilot",
  "api2.cursor.sh" => "🖱️ Cursor",
  "api.perplexity.ai" => "🔍 Perplexity",
  "api.x.ai" => "𝕏 xAI / Grok",
  "grok.com" => "𝕏 xAI / Grok",
  "huggingface.co" => "🤗 Hugging Face",
  "server.codeium.com" => "🏄 Windsurf",
  "api.jetbrains.ai" => "🧠 JetBrains AI"
}.freeze
errors = []

def lines(path)
  File.readlines(File.join(ROOT, path), chomp: true)
end

def section(path, name)
  active = false
  lines(path).each_with_object([]) do |line, result|
    line = line.strip
    if line == "[#{name}]"
      active = true
      next
    end
    active = false if line.start_with?("[")
    result << line if active
  end
end

def entries(path, name)
  section(path, name).map(&:strip).reject { |line| line.empty? || line.start_with?("#", ";", "//") }
end

def groups(path)
  entries(path, "Proxy Group").map { |line| line.split("=", 2).first.strip }
end

def rule_policy(line)
  fields = line.split(",").map(&:strip)
  %w[FINAL MATCH].include?(fields.first.upcase) ? fields[1] : fields[2]
end

def normalized_rule(line)
  fields = line.split(",").map(&:strip)
  fields[0] = fields[0].upcase.sub(/^HOST/, "DOMAIN")
  fields
end

def matching_domain_rule(rules, host)
  rules.map { |line| normalized_rule(line) }.find do |kind, value, _policy|
    case kind
    when "DOMAIN" then host == value
    when "DOMAIN-SUFFIX" then host == value || host.end_with?(".#{value}")
    when "DOMAIN-KEYWORD" then host.include?(value)
    end
  end
end

def check_rule_refs(path, known, errors, section_name = "Rule")
  entries(path, section_name).each do |line|
    policy = rule_policy(line)
    errors << "#{path}: unresolved policy #{policy.inspect} in #{line.inspect}" unless known.include?(policy)
  end
end

def group_members(line)
  fields = line.split("=", 2).last.split(",").map(&:strip)
  fields.drop(1).take_while { |field| !field.include?("=") }
end

def check_groups(path, available, errors)
  own = groups(path)
  errors << "#{path}: duplicate group name" unless own.uniq == own

  entries(path, "Proxy Group").each do |line|
    name = line.split("=", 2).first.strip
    group_members(line).each do |member|
      next if (available + BUILT_INS).include?(member)
      errors << "#{path}: #{name.inspect} references unknown group #{member.inspect}"
    end
  end

  graph = own.to_h do |name|
    line = entries(path, "Proxy Group").find { |entry| entry.split("=", 2).first.strip == name }
    [name, group_members(line).select { |member| own.include?(member) }]
  end
  visiting = {}
  visit = lambda do |name|
    return errors << "#{path}: policy-group cycle through #{name.inspect}" if visiting[name] == :active
    return if visiting[name] == :done
    visiting[name] = :active
    graph.fetch(name, []).each { |child| visit.call(child) }
    visiting[name] = :done
  end
  own.each { |name| visit.call(name) }
end

def require_text(body, text, label, errors)
  errors << "#{label}: missing #{text.inspect}" unless body.include?(text)
end

def forbid_text(body, text, label, errors)
  errors << "#{label}: contains retired or unsafe text #{text.inspect}" if body.include?(text)
end

def check_final(path, rules, errors)
  finals = rules.select { |line| line.match?(/\A(?:FINAL|MATCH),/i) }
  errors << "#{path}: expected exactly one final rule, at the end" unless finals.size == 1 && rules.last == finals.first
end

base_groups = groups(BASE)
check_groups(BASE, base_groups, errors)
check_rule_refs(BASE, base_groups + BUILT_INS, errors)
check_final(BASE, entries(BASE, "Rule"), errors)

available_modules = Dir.glob(File.join(ROOT, "modules/*.module")).map { |path| File.basename(path, ".module") }
selected_modules = ARGV.map { |arg| File.basename(arg, ".module") }.uniq
(selected_modules - available_modules).each { |name| errors << "unknown selected module #{name.inspect}" }
MODULE_CONFLICTS.each do |pair|
  errors << "selected modules conflict: #{pair.join(" and ")}" if (pair - selected_modules).empty?
end
if selected_modules.include?("adblock-aggressive") && !selected_modules.include?("adblock-core")
  errors << "adblock-aggressive requires adblock-core"
end
# Arguments follow the top-to-bottom module order documented in recipes.md.
before_pairs = available_modules.grep(/^apple-/).reject { |name| %w[apple-services apple-app-store-cdn].include?(name) }.map { |name| [name, "apple-services"] }
%w[back-to-cn back-to-cn-all].each do |travel|
  %w[adblock-core adblock-lite adblock-aggressive httpdns-block soul-ktv].each { |name| before_pairs << [name, travel] }
end
%w[adblock-core adblock-lite adblock-aggressive httpdns-block].each { |name| before_pairs << [name, "soul-ktv"] }
before_pairs << ["adblock-core", "adblock-aggressive"]
%w[bulk-downloads regional-streaming network-diagnostics].each do |optional|
  %w[adblock-core adblock-lite adblock-aggressive httpdns-block].each { |block| before_pairs << [block, optional] }
  %w[back-to-cn back-to-cn-all].each { |travel| before_pairs << [optional, travel] }
end
before_pairs.each do |first, last|
  first_index, last_index = [first, last].map { |name| selected_modules.index(name) }
  errors << "module order: #{first} must precede #{last}" if first_index && last_index && first_index > last_index
end
selected_groups = base_groups + (selected_modules & available_modules).flat_map do |name|
  groups("modules/#{name}.module")
end
duplicate_selected_groups = selected_groups.group_by(&:itself).select { |_name, values| values.length > 1 }.keys
errors << "selected modules define duplicate groups: #{duplicate_selected_groups.join(", ")}" unless duplicate_selected_groups.empty?

Dir.glob(File.join(ROOT, "modules/*.module")).sort.each do |absolute|
  path = absolute.delete_prefix("#{ROOT}/")
  check_groups(path, base_groups + groups(path), errors)
  check_rule_refs(path, base_groups + groups(path) + BUILT_INS, errors)
end

surge_groups = groups(SURGE)
check_groups(SURGE, surge_groups, errors)
check_rule_refs(SURGE, surge_groups + BUILT_INS, errors)
check_final(SURGE, entries(SURGE, "Rule"), errors)
entries(SURGE, "Proxy Group").grep(/= url-test,/).each do |line|
  %w[include-all-proxies=true include-other-group=PROXY].each do |source|
    require_text(line, source, "#{SURGE}: regional node sourcing", errors)
  end
end

clash = YAML.safe_load(File.read(File.join(ROOT, CLASH)), aliases: false)
clash_groups = clash.fetch("proxy-groups").map { |group| group.fetch("name") }
clash_providers = clash.fetch("rule-providers").keys
errors << "#{CLASH}: duplicate group name" unless clash_groups.uniq == clash_groups
clash.fetch("proxy-groups").each do |group|
  group.fetch("proxies", []).each do |member|
    errors << "#{CLASH}: #{group.fetch("name")} references unknown group #{member.inspect}" unless (clash_groups + BUILT_INS).include?(member)
  end
end
clash.fetch("rules").each do |rule|
  fields = rule.split(",").map(&:strip)
  if fields.first == "RULE-SET"
    errors << "#{CLASH}: unknown provider #{fields[1].inspect}" unless clash_providers.include?(fields[1])
    policy = fields[2]
  else
    policy = fields.first == "MATCH" ? fields[1] : fields[2]
  end
  errors << "#{CLASH}: unknown policy #{policy.inspect}" unless (clash_groups + BUILT_INS).include?(policy)
end
check_final(CLASH, clash.fetch("rules"), errors)

qx_policies = entries(QX, "policy").each_with_object([]) do |line, policies|
  next unless line.start_with?("static=", "url-latency-benchmark=")
  policies << line.split("=", 2).last.split(",", 2).first.strip
end
errors << "#{QX}: duplicate policy name" unless qx_policies.uniq == qx_policies
entries(QX, "policy").grep(/^static=/).each do |line|
  name, *members = line.split("=", 2).last.split(",").map(&:strip)
  members.take_while { |field| !field.include?("=") }.each do |member|
    errors << "#{QX}: #{name.inspect} references unknown policy #{member.inspect}" unless (qx_policies + BUILT_INS).include?(member)
  end
end
entries(QX, "filter_remote").each do |line|
  policy = line[/force-policy=([^,]+)/, 1]&.strip || line[/tag=([^,]+)/, 1]&.strip
  errors << "#{QX}: remote filter has no resolvable policy in #{line.inspect}" unless (qx_policies + BUILT_INS).include?(policy)
end
check_rule_refs(QX, qx_policies + BUILT_INS, errors, "filter_local")
check_final(QX, entries(QX, "filter_local"), errors)

(["🤖 OpenAI", "🧠 Claude", "💎 Google AI"] + NEW_AI_CASES.values.uniq).each do |name|
  [BASE, SURGE, QX, CLASH].each do |path|
    first = if path == CLASH
              clash.fetch("proxy-groups").find { |group| group["name"] == name }&.fetch("proxies", [])&.first
            else
              group_line = entries(path, path == QX ? "policy" : "Proxy Group").find do |line|
                path == QX ? line.start_with?("static=#{name},") : line.split("=", 2).first.strip == name
              end
              group_line && group_members(group_line).first
            end
    errors << "#{path}: #{name} must default to the US group" unless first == "🇺🇸 US Node"
  end
end

# Manual DIRECT choices never change the existing first/default candidate.
[BASE, SURGE].each do |path|
  entries(path, "Proxy Group").grep(/= select,/).each do |line|
    errors << "#{path}: selector lacks DIRECT: #{line.split('=', 2).first}" unless group_members(line).include?("DIRECT")
  end
end
clash.fetch("proxy-groups").select { |group| group["type"] == "select" && group["name"] != "PROXY" }.each do |group|
  errors << "#{CLASH}: #{group['name']} lacks DIRECT" unless group.fetch("proxies", []).include?("DIRECT")
end
entries(QX, "policy").grep(/^static=/).each do |line|
  errors << "#{QX}: selector lacks direct" unless line.split(",").map(&:strip).include?("direct")
end

config_paths = [BASE, SURGE, CLASH, QX] + Dir.glob(File.join(ROOT, "modules/*.module")).map { |path| path.delete_prefix("#{ROOT}/") }
all_config = config_paths.to_h do |path|
  active = lines(path).reject { |line| line.strip.start_with?("#", ";", "//") }
  [path, active.join("\n")]
end
unsafe = [
  "/Rules/Direct.list",
  "/Rules/Reject.list",
  "ai-proxy-rules",
  "/Rules/AI.list",
  "DEST-PORT,22",
  "DOMAIN-SUFFIX,ai.com,🤖 OpenAI",
  "host-suffix, ai.com, 🤖 OpenAI",
  "🇨🇳 Taiwan Node"
]
all_config.each do |path, body|
  unsafe.each { |text| forbid_text(body, text, path, errors) }
  if path != "modules/adblock-aggressive.module"
    forbid_text(body, "anti-ad.net/surge.txt", path, errors)
  end
end

# These upstream RULE-SET files deliberately omit their domain-only payload.
{
  BASE => %w[ChinaMax],
  SURGE => %w[Apple ChinaMax],
  "modules/adblock-core.module" => %w[Advertising],
  "modules/adblock-lite.module" => %w[AdvertisingLite]
}.each do |path, names|
  rules = entries(path, "Rule")
  names.each do |name|
    mixed = rules.find { |line| line.start_with?("RULE-SET,") && line.include?("/#{name}/#{name}.list,") }
    if mixed
      companion = mixed.sub("RULE-SET,", "DOMAIN-SET,").sub("/#{name}.list,", "/#{name}_Domain.list,")
      errors << "#{path}: missing matching DOMAIN-SET for #{name}" unless rules.include?(companion)
    else
      errors << "#{path}: missing RULE-SET for #{name}"
    end
  end
end
forbid_text(all_config.fetch("modules/adblock-core.module"), "/Privacy/", "Core already includes Privacy", errors)

main = all_config.fetch(BASE)
expected_skip_proxy = "skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 127.0.0.1, localhost, *.local, captive.apple.com"
errors << "#{BASE}: skip-proxy must contain local access only" unless main.lines.map(&:strip).grep(/^skip-proxy\s*=/) == [expected_skip_proxy]
errors << "#{BASE}: base policy must not reject traffic" if entries(BASE, "Rule").any? { |line| rule_policy(line) == "REJECT" }
forbid_text(main, "block-quic =", BASE, errors)
%w[stripe.com auth0.com sentry.io intercom.io api.cloudflare.com].each { |domain| forbid_text(main, domain, BASE, errors) }

service_routes = {
  "Claude.list" => "🧠 Claude",
  "Gemini.list" => "💎 Google AI",
  "Github.list" => "💻 Developer Services",
  "YouTube.list" => "▶️ YouTube",
  "Netflix.list" => "🎬 Netflix",
  "Disney.list" => "🏰 Disney+",
  "PrimeVideo.list" => "📦 Prime Video",
  "HBO.list" => "📺 HBO",
  "Bahamut.list" => "🐉 Bahamut"
}
service_routes.each { |source, policy| require_text(main, "#{source},#{policy}", BASE, errors) }
require_text(main, "DOMAIN-SUFFIX,openai.com,🤖 OpenAI", BASE, errors)
forbid_text(main, "/OpenAI/OpenAI.", BASE, errors)

%w[adblock-core adblock-lite adblock-aggressive].each do |name|
  path = "modules/#{name}.module"
  body = all_config.fetch(path)
  %w[token.safebrowsing.apple safebrowsing.googleapis.com safebrowsing.googleapis-cn.com safebrowsing.urlsec.qq.com].each do |domain|
    require_text(body, "DOMAIN,#{domain},DIRECT", path, errors)
  end
  first_remote = entries(path, "Rule").index { |line| line.start_with?("RULE-SET,") }
  errors << "#{path}: security allowlist must precede remote blocking" unless first_remote && first_remote >= 4
end

privacy_dns = all_config.fetch("modules/privacy-dns.module")
{
  "dns-server" => "https://cloudflare-dns.com/dns-query",
  "fallback-dns-server" => "https://dns.quad9.net/dns-query",
  "dns-direct-system" => "false",
  "dns-direct-fallback-proxy" => "false",
  "hijack-dns" => "*:53"
}.each do |setting, value|
  require_text(privacy_dns, "#{setting} = #{value}", "modules/privacy-dns.module", errors)
  errors << "#{BASE}: #{setting} must stay optional" if main.match?(/^#{Regexp.escape(setting)}\s*=/)
end

security_dns = all_config.fetch("modules/security-dns.module")
{
  "dns-server" => "https://security.cloudflare-dns.com/dns-query",
  "fallback-dns-server" => "https://dns.quad9.net/dns-query",
  "dns-direct-system" => "false",
  "dns-direct-fallback-proxy" => "false",
  "hijack-dns" => "*:53"
}.each do |setting, value|
  actual = entries("modules/security-dns.module", "General").grep(/^#{Regexp.escape(setting)}\s*=/)
  errors << "security-dns: #{setting} must use only the reviewed security setting" unless actual == ["#{setting} = #{value}"]
end

china_dns = all_config.fetch("modules/dns-mainland-china.module")
require_text(china_dns, "dns-server = https://dns.alidns.com/dns-query#no-h3", "modules/dns-mainland-china.module", errors)
require_text(china_dns, "fallback-dns-server = https://doh.pub/dns-query#no-h3", "modules/dns-mainland-china.module", errors)
require_text(all_config.fetch("modules/quic-compat.module"), "block-quic = all-proxy", "modules/quic-compat.module", errors)
require_text(all_config.fetch("modules/ipv6.module"), "prefer-ipv6 = false", "modules/ipv6.module", errors)
require_text(all_config.fetch("modules/ipv6-preferred.module"), "prefer-ipv6 = true", "modules/ipv6-preferred.module", errors)

certificate_hosts = %w[certs.apple.com crl.apple.com crl3.digicert.com crl4.digicert.com ocsp.apple.com ocsp.digicert.cn ocsp.digicert.com ocsp2.apple.com valid.apple.com appattest.apple.com]
apple_expectations = {
  "modules/apple-account.module" => %w[account.apple.com appleid.cdn-apple.com idmsa.apple.com gsa.apple.com setup.icloud.com],
  "modules/apple-certificate-validation.module" => certificate_hosts,
  "modules/apple-push.module" => %w[push.apple.com push-apple.com.akadns.net],
  "modules/apple-app-downloads.module" => %w[itunes.apple.com apps.apple.com mzstatic.com download.developer.apple.com],
  "modules/apple-updates.module" => %w[configuration.apple.com gdmf.apple.com osrecovery.apple.com updates.cdn-apple.com],
  "modules/apple-siri-search.module" => %w[guzzoni.apple.com smoot.apple.com],
  "modules/apple-intelligence.module" => %w[apple-relay.apple.com apple-relay.cloudflare.com apple-relay.fastly-edge.com cp4.cloudflare.com]
}
apple_expectations.each do |path, domains|
  domains.each { |domain| require_text(all_config.fetch(path), domain, path, errors) }
end
forbid_text(all_config.fetch("modules/apple-updates.module"), "gateway.icloud.com", "modules/apple-updates.module", errors)
%w[guzzoni.apple.com smoot.apple.com].each { |host| forbid_text(all_config.fetch("modules/apple-intelligence.module"), host, "modules/apple-intelligence.module", errors) }
%w[apple-relay.apple.com apple-relay.cloudflare.com apple-relay.fastly-edge.com cp4.cloudflare.com].each { |host| forbid_text(all_config.fetch("modules/apple-siri-search.module"), host, "modules/apple-siri-search.module", errors) }

certificate_rule_sets = {
  "modules/apple-certificate-validation.module" => entries("modules/apple-certificate-validation.module", "Rule"),
  SURGE => entries(SURGE, "Rule"),
  CLASH => clash.fetch("rules"),
  QX => entries(QX, "filter_local")
}
certificate_rule_sets.each do |path, rules|
  certificate_hosts.each do |host|
    matches = rules.map { |rule| rule.split(",").map(&:strip) }.select { |fields| fields[1] == host }
    errors << "#{path}: missing direct certificate rule for #{host}" if matches.empty?
    errors << "#{path}: certificate rule for #{host} must use DIRECT" unless matches.all? { |fields| fields[2]&.casecmp("DIRECT")&.zero? }
  end
end

siri_group_lines = {
  "modules/apple-siri-search.module" => entries("modules/apple-siri-search.module", "Proxy Group").find { |line| line.start_with?("🗣️ Siri & Search") },
  SURGE => entries(SURGE, "Proxy Group").find { |line| line.start_with?("🗣️ Siri & Search") },
  QX => entries(QX, "policy").find { |line| line.start_with?("static=🗣️ Siri & Search") }
}
siri_group_lines.each do |path, line|
  errors << "#{path}: Siri & Search must default to DIRECT" unless line && group_members(line).first&.casecmp("DIRECT")&.zero?
end
clash_siri = clash.fetch("proxy-groups").find { |group| group.fetch("name") == "🗣️ Siri & Search" }
errors << "#{CLASH}: Siri & Search must default to DIRECT" unless clash_siri&.fetch("proxies", [])&.first == "DIRECT"

targeted = all_config.fetch("modules/back-to-cn.module")
all_cn = all_config.fetch("modules/back-to-cn-all.module")
%w[WeChat AliPay BiliBili NetEaseMusic ChinaMedia].each { |source| require_text(targeted, "/#{source}/#{source}.list", "modules/back-to-cn.module", errors) }
forbid_text(targeted, "ChinaIPs.list", "modules/back-to-cn.module", errors)
require_text(all_cn, "china-domain-list", "modules/back-to-cn-all.module", errors)
require_text(all_cn, "ChinaIPs.list", "modules/back-to-cn-all.module", errors)

common_groups = service_routes.values + ["📲 Apple App Downloads", "🍏 Apple Updates", "🗣️ Siri & Search", "🧠 Apple PCC", "🔔 Apple Push", "🔐 Apple Account", "🍎 Apple Services"]
common_groups << "🤖 OpenAI"
{ SURGE => surge_groups, CLASH => clash_groups, QX => qx_policies }.each do |path, known|
  common_groups.each { |group| errors << "#{path}: missing policy #{group.inspect}" unless known.include?(group) }
end

{
  SURGE => {
    "DOMAIN,guzzoni.apple.com,🗣️ Siri & Search" => "Siri",
    "DOMAIN,apple-relay.apple.com,🧠 Apple PCC" => "Apple Intelligence",
    "DOMAIN,configuration.apple.com,🍏 Apple Updates" => "updates",
    "DOMAIN-SUFFIX,itunes.apple.com,📲 Apple App Downloads" => "downloads"
  },
  CLASH => {
    "DOMAIN,guzzoni.apple.com,🗣️ Siri & Search" => "Siri",
    "DOMAIN,apple-relay.apple.com,🧠 Apple PCC" => "Apple Intelligence",
    "DOMAIN,configuration.apple.com,🍏 Apple Updates" => "updates",
    "DOMAIN-SUFFIX,itunes.apple.com,📲 Apple App Downloads" => "downloads"
  },
  QX => {
    "host, guzzoni.apple.com, 🗣️ Siri & Search" => "Siri",
    "host, apple-relay.apple.com, 🧠 Apple PCC" => "Apple Intelligence",
    "host, configuration.apple.com, 🍏 Apple Updates" => "updates",
    "host-suffix, itunes.apple.com, 📲 Apple App Downloads" => "downloads"
  }
}.each do |path, checks|
  checks.each_key { |text| require_text(all_config.fetch(path), text, path, errors) }
end

require_text(clash.dig("dns", "nameserver").to_a.join(" "), "dns.quad9.net", CLASH, errors)
require_text(all_config.fetch(SURGE), "encrypted-dns-server = https://1.1.1.1/dns-query, https://dns.quad9.net/dns-query", SURGE, errors)
require_text(all_config.fetch(QX), "doh-server = https://1.1.1.1/dns-query, https://dns.quad9.net/dns-query", QX, errors)
errors << "#{CLASH}: DNS must bind to localhost" unless clash.dig("dns", "listen") == "127.0.0.1:1053"
errors << "#{QX}: excluded routes need CIDR masks" unless all_config.fetch(QX).include?("excluded_routes = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 127.0.0.0/8, 100.64.0.0/10")

# Check any repository revision, not just a blacklist of familiar branch names.
config_paths.each do |path|
  lines(path).each do |line|
    next if line.strip.start_with?("#", ";", "//", "update-url =")
    line.scan(%r{https://[^\s,"']+}).each do |url|
      uri = URI(url)
      revision = case uri.host
                 when "raw.githubusercontent.com" then uri.path.split("/")[3]
                 when "github.com" then uri.path[%r{\A/[^/]+/[^/]+/raw/(?:refs/heads/)?([^/]+)}, 1]
                 when "cdn.jsdelivr.net" then uri.path[%r{\A/gh/[^/]+/[^/@]+@([^/]+)}, 1]
                 else next
                 end
      errors << "#{path}: source must use a full commit ID: #{url}" unless revision&.match?(/\A[0-9a-f]{40}\z/)
    end
  end
end

readme = File.read(File.join(ROOT, "README.md"))
Dir.glob(File.join(ROOT, "modules/*.module")).sort.each do |absolute|
  filename = File.basename(absolute)
  require_text(readme, "modules/#{filename}", "README.md", errors)
  require_text(readme, "https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/#{filename}", "README.md", errors)
  require_text(readme, "https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/#{filename}", "README.md", errors)
end
recipes = File.read(File.join(ROOT, "docs/recipes.md"))
MODULE_CONFLICTS.each do |pair|
  pair.each { |name| require_text(recipes, name, "docs/recipes.md", errors) }
end

# Offline hostname checks cover local routing and precedence, not DNS/IP/native behavior.
client_rules = { BASE => entries(BASE, "Rule"), SURGE => entries(SURGE, "Rule"), CLASH => clash.fetch("rules"), QX => entries(QX, "filter_local") }
reference_ai = entries(BASE, "Rule").map { |line| normalized_rule(line) }.select { |fields| NEW_AI_CASES.value?(fields[2]) }
client_rules.each do |path, rules|
  ai_rules = rules.select { |line| NEW_AI_CASES.value?(rule_policy(line)) }
  normalized = ai_rules.map { |line| normalized_rule(line) }
  errors << "#{path}: new AI provider rules differ from the base" unless normalized == reference_ai
  errors << "#{path}: AI providers require narrow domain rules" unless normalized.all? { |kind, _, _| %w[DOMAIN DOMAIN-SUFFIX].include?(kind) }
  NEW_AI_CASES.each do |host, policy|
    actual = matching_domain_rule(rules, host)&.[](2)
    errors << "#{path}: routing case #{host} expected #{policy}, got #{actual.inspect}" unless actual == policy
  end
  %w[api.github.com github.com login.microsoftonline.com api.stripe.com cloudfront.net ai.com raw.githubusercontent.com other.s3.amazonaws.com other.blob.core.windows.net].each do |host|
    errors << "#{path}: AI rules capture shared/non-provider host #{host}" if matching_domain_rule(ai_rules, host)
  end
  unless path == QX # Local filters take precedence over QX remote filters.
    first_broad = rules.index { |line| line.match?(%r{(?:/(?:Github|GitHub|Microsoft|Twitter|Proxy|CDN)\.list,|RULE-SET,(?:github|microsoft|twitter|proxy|geolocation-!cn),)}i) }
    last_ai = rules.rindex { |line| NEW_AI_CASES.value?(rule_policy(line)) }
    errors << "#{path}: AI provider rules must precede broad service rules" unless first_broad && last_ai && last_ai < first_broad
  end
end

module_cases = {
  "bulk-downloads" => { "cdn.steamcontent.com" => "⬇️ Bulk Downloads", "download.windowsupdate.com" => "⬇️ Bulk Downloads", "files.pythonhosted.org" => "⬇️ Bulk Downloads", "static.crates.io" => "⬇️ Bulk Downloads", "steamcommunity.com" => nil, "api.steampowered.com" => nil, "api.github.com" => nil, "pypi.org" => nil, "crates.io" => nil, "apps.apple.com" => nil },
  "regional-streaming" => { "viu.tv" => "🇭🇰 HK Streaming", "mytvsuper.com" => "🇭🇰 HK Streaming", "nowe.com" => "🇭🇰 HK Streaming", "kktv.me" => "🇹🇼 TW Streaming", "ana.video.friday.tw" => "🇹🇼 TW Streaming", "abema.tv" => "🇯🇵 JP Streaming", "tver.jp" => "🇯🇵 JP Streaming", "players.brightcove.net" => nil, "unrelated.cloudfront.net" => nil },
  "network-diagnostics" => { "www.speedtest.net" => "📶 Network Diagnostics", "example.ooklaserver.net" => "📶 Network Diagnostics", "fast.com" => nil, "netflix.com" => nil }
}
module_cases.each do |name, cases|
  path = "modules/#{name}.module"
  rules = entries(path, "Rule")
  errors << "#{path}: optional routing must contain narrow domain rules only" unless rules.all? { |line| %w[DOMAIN DOMAIN-SUFFIX].include?(normalized_rule(line).first) }
  cases.each do |host, expected|
    actual = matching_domain_rule(rules, host)&.[](2)
    errors << "#{path}: routing case #{host} expected #{expected.inspect}, got #{actual.inspect}" unless actual == expected
  end
  groups(path).each do |name|
    errors << "#{name}: optional module leaked into base/export" if [base_groups, surge_groups, clash_groups, qx_policies].any? { |known| known.include?(name) }
  end
end

if errors.empty?
  puts "All config checks passed."
else
  warn errors.uniq.join("\n")
  exit 1
end
