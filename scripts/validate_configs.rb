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
errors << "#{qx_path}: DoH is not enabled" unless qx.any? { |line| line.start_with?("doh-server = https://") }

all_config = (["shadowrocket.conf"] + Dir.glob(File.join(ROOT, "modules/*.module")).map { |path| path.delete_prefix("#{ROOT}/") } + %w[exports/clash/config.yaml exports/surge/Surge.conf exports/quantumultx/QuantumultX.conf]).to_h { |path| [path, File.read(File.join(ROOT, path))] }
banned = ["Apple-Push.list", "/Advertising/Privacy.list", "/Forbidden/Forbidden.list", "sr_ad_only.conf", "carrnot/china-ip-list", "🇨🇳 Taiwan Node"]
banned.each do |text|
  all_config.each { |path, body| errors << "#{path}: contains retired text #{text.inspect}" if body.include?(text) }
end

main = all_config.fetch("shadowrocket.conf")
errors << "shadowrocket.conf: private DNS answers must not be accepted" unless main.include?("private-ip-answer = false")
errors << "shadowrocket.conf: Apple routing must stay in its module" if main.include?("🍎 Apple Services")
errors << "shadowrocket.conf: Reject must precede broad AI rules" unless precedes?(main, "Rules/Reject.list", "ai-proxy-rules")
errors << "shadowrocket.conf: full RFC1918 LAN range is missing" unless main.include?("skip-proxy = 192.168.0.0/16")

apple = all_config.fetch("modules/apple-services.module")
first_apple_list = apple.index("RULE-SET")
%w[gateway.icloud.com swscan.apple.com].each do |domain|
  errors << "modules/apple-services.module: #{domain} must precede broad Apple lists" unless apple.index(domain) < first_apple_list
end

surge = all_config.fetch("exports/surge/Surge.conf")
errors << "exports/surge/Surge.conf: Reject must precede broad AI rules" unless precedes?(surge, "Rules/Reject.list", "ai-proxy-rules")
errors << "exports/surge/Surge.conf: Apple exceptions must precede broad Apple lists" unless precedes?(surge, "gateway.icloud.com,DIRECT", "rule/Surge/Apple/Apple.list")

clash_rules = clash.fetch("rules")
errors << "exports/clash/config.yaml: ads must precede broad AI rules" unless clash_rules.index("RULE-SET,ads,REJECT") < clash_rules.index("RULE-SET,ai-vpsdance,🤖 AI")
errors << "exports/clash/config.yaml: Apple exceptions must precede broad Apple lists" unless clash_rules.index("DOMAIN-SUFFIX,gateway.icloud.com,DIRECT") < clash_rules.index("RULE-SET,apple,🍎 Apple Services")

errors << "#{qx_path}: ad filters must precede AI filters" unless precedes?(all_config.fetch(qx_path), "/Advertising/Advertising.list", "/OpenAI/OpenAI.list")
errors << "#{qx_path}: excluded routes need CIDR masks" unless all_config.fetch(qx_path).include?("excluded_routes = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 127.0.0.0/8, 100.64.0.0/10")

if errors.empty?
  puts "All config checks passed."
else
  warn errors.join("\n")
  exit 1
end
