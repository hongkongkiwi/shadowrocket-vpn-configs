#!/usr/bin/env ruby

require "fileutils"
require "open3"
require "tmpdir"

root = File.expand_path("..", __dir__)
checks = 0
check = lambda do |directory, modules, expected_error = nil|
  output, status = Open3.capture2e(RbConfig.ruby, "scripts/validate_configs.rb", *modules, chdir: directory)
  passed = expected_error ? !status.success? && output.include?(expected_error) : status.success?
  abort "Validator regression for #{modules.inspect}: #{output}" unless passed
  checks += 1
end

check.call(root, [])
check.call(root, %w[adblock-core adblock-aggressive privacy-dns apple-account apple-services soul-ktv back-to-cn ipv6])
check.call(root, %w[apple-services apple-app-store-cdn]) # Host alias has no rule-order dependency.
check.call(root, %w[adblock-core security-dns bulk-downloads regional-streaming network-diagnostics back-to-cn])
[%w[adblock-core adblock-lite], %w[privacy-dns dns-mainland-china], %w[security-dns privacy-dns], %w[security-dns dns-mainland-china], %w[back-to-cn back-to-cn-all], %w[ipv6 ipv6-preferred]].each do |pair|
  check.call(root, pair, "selected modules conflict")
end
check.call(root, %w[adblock-aggressive], "requires adblock-core")
check.call(root, %w[adblock-lite adblock-aggressive], "requires adblock-core")
[%w[apple-services apple-account], %w[back-to-cn soul-ktv], %w[soul-ktv httpdns-block], %w[back-to-cn adblock-core], %w[adblock-aggressive adblock-core], %w[bulk-downloads adblock-core], %w[back-to-cn-all regional-streaming], %w[network-diagnostics httpdns-block]].each do |pair|
  check.call(root, pair, "module order:")
end
check.call(root, %w[missing-module], "unknown selected module")

# Mutate an isolated copy so these checks can't alter installed/user configs.
Dir.mktmpdir("shadowrocket-validator-") do |scratch|
  %w[scripts modules exports docs README.md shadowrocket.conf].each do |entry|
    FileUtils.cp_r(File.join(root, entry), scratch)
  end
  {
    "shadowrocket.conf" => ["DOMAIN-SUFFIX,openai.com,🤖 OpenAI", "# DOMAIN-SUFFIX,openai.com,🤖 OpenAI", "missing"],
    "exports/clash/config.yaml" => ['proxies: [🇺🇸 US Node, PROXY,', 'proxies: [PROXY, 🇺🇸 US Node,', "must default to the US group"],
    "exports/surge/Surge.conf" => ['🤖 OpenAI = select, 🇺🇸 US Node, PROXY,', '🤖 OpenAI = select, PROXY, 🇺🇸 US Node,', "must default to the US group"],
    "exports/quantumultx/QuantumultX.conf" => ['static=🤖 OpenAI, 🇺🇸 US Node, proxy,', 'static=🤖 OpenAI, proxy, 🇺🇸 US Node,', "must default to the US group"]
  }.each do |relative, (before, after, error)|
    filename = File.join(scratch, relative)
    original = File.read(filename)
    # Change all matches: the mihomo list also appears in TikTok.
    changed = original.gsub(before, after)
    abort "Mutation target missing: #{relative}" if changed == original
    File.write(filename, changed)
    check.call(scratch, [], error)
    File.write(filename, original)
  end

  {
    "modules/security-dns.module" => ["https://security.cloudflare-dns.com/dns-query", "https://cloudflare-dns.com/dns-query", "must use only the reviewed security setting"],
    "modules/bulk-downloads.module" => ["DOMAIN-SUFFIX,steamcontent.com", "DOMAIN-SUFFIX,steamcommunity.com", "routing case"],
    "modules/network-diagnostics.module" => ["DOMAIN-SUFFIX,speedtest.net", "DOMAIN-SUFFIX,fast.com", "routing case"],
    "shadowrocket.conf" => ["DOMAIN-SUFFIX,githubcopilot.com,🧑‍💻 GitHub Copilot", "DOMAIN-SUFFIX,githubcopilot.com,💻 Developer Services", "routing case api.githubcopilot.com"]
  }.each do |relative, (before, after, error)|
    filename = File.join(scratch, relative)
    original = File.read(filename)
    abort "Mutation target missing: #{relative}" unless original.include?(before)
    File.write(filename, original.sub(before, after))
    check.call(scratch, [], error)
    File.write(filename, original)
  end

  filename = File.join(scratch, "shadowrocket.conf")
  original = File.read(filename)
  rule = "DOMAIN-SUFFIX,githubcopilot.com,🧑‍💻 GitHub Copilot"
  File.write(filename, original.sub("#{rule}\n", "").sub("FINAL,", "#{rule}\nFINAL,"))
  check.call(scratch, [], "must precede broad service rules")
  File.write(filename, original)

  before, after = %w[old.list new.list].map { |name| File.join(scratch, name) }
  File.write(before, "DOMAIN,old.example\n")
  File.write(after, "DOMAIN,api.githubcopilot.com\n")
  output, status = Open3.capture2e(RbConfig.ruby, "scripts/audit_remote_sources.rb", "--compare", before, after, chdir: root)
  abort "Safe source comparison failed: #{output}" unless status.success? && output.include?("1 added, 1 removed")
  checks += 1
  File.write(after, "DOMAIN-SUFFIX,ai\nIP-ASN,14061\nDOMAIN,api.github.com\n")
  output, status = Open3.capture2e(RbConfig.ruby, "scripts/audit_remote_sources.rb", "--compare", before, after, chdir: root)
  abort "Missed source scope expansion: #{output}" unless !status.success? && %w[top-level network shared].all? { |word| output.include?(word) }
  checks += 1
  File.write(before, "DOMAIN-SUFFIX,example.com\nDOMAIN,api.example.com\n")
  File.write(after, "DOMAIN,api.example.com\nDOMAIN-SUFFIX,example.com\n")
  output, status = Open3.capture2e(RbConfig.ruby, "scripts/audit_remote_sources.rb", "--compare", before, after, chdir: root)
  abort "Missed reordered source rules: #{output}" unless !status.success? && output.include?("relative rule order changed")
  checks += 1
  File.write(before, "DOMAIN,old.example\n")
  shared = %w[s3.amazonaws.com blob.core.windows.net githubusercontent.com]
  File.write(after, shared.map { |host| "DOMAIN-SUFFIX,#{host}\n" }.join)
  output, status = Open3.capture2e(RbConfig.ruby, "scripts/audit_remote_sources.rb", "--compare", before, after, chdir: root)
  abort "Missed shared tenant suffixes: #{output}" unless !status.success? && shared.all? { |host| output.include?("shared service/CDN scope: DOMAIN-SUFFIX,#{host}") }
  checks += 1
end
# Exercise the push guard without changing refs or contacting a remote.
guard = File.join(root, ".lefthook/pre-push/no-direct-main.sh")
{
  "" => true,
  "refs/heads/topic abc refs/heads/topic def\n" => true,
  "refs/heads/topic abc refs/heads/main def\n" => false,
  "refs/heads/topic abc refs/heads/master def\n" => false,
  "refs/heads/topic abc refs/heads/topic def\n(delete) 000 refs/heads/main def\n" => false
}.each do |input, expected_success|
  output, status = Open3.capture2e("sh", guard, stdin_data: input)
  abort "Push guard regression for #{input.inspect}: #{output}" unless status.success? == expected_success
  checks += 1
end
puts "Config validator regression checks passed (#{checks} cases)."
