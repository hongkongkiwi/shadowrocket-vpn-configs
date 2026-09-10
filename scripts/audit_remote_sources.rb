#!/usr/bin/env ruby

require "digest"
require "open-uri"
require "thread"
require "yaml"

ROOT = File.expand_path("..", __dir__)
PATHS = [
  "shadowrocket.conf",
  *Dir.glob(File.join(ROOT, "modules/*.module")).map { |path| path.delete_prefix("#{ROOT}/") },
  "exports/clash/config.yaml",
  "exports/surge/Surge.conf",
  "exports/quantumultx/QuantumultX.conf"
].freeze
SOURCE_HOSTS = %w[anti-ad.net cdn.jsdelivr.net github.com raw.githubusercontent.com].freeze
AI_SHARED_DEPENDENCIES = %w[stripe.com auth0.com sentry.io intercom.io api.cloudflare.com].freeze
SHARED_SCOPE = (AI_SHARED_DEPENDENCIES + %w[api.github.com githubusercontent.com cloudflare.com cloudfront.net amazonaws.com windows.net azureedge.net azurefd.net akamaized.net akamaihd.net fastly.net brightcove.net cloudinary.com workers.dev pages.dev vercel.app netlify.app]).freeze
RULE_TYPES = %w[DOMAIN DOMAIN-SUFFIX DOMAIN-KEYWORD DOMAIN-WILDCARD DOMAIN-REGEX HOST HOST-SUFFIX HOST-KEYWORD HOST-WILDCARD IP-CIDR IP-CIDR6 IP6-CIDR IP-ASN GEOIP USER-AGENT URL-REGEX PROCESS-NAME PROCESS-PATH DST-PORT SRC-PORT AND OR NOT].freeze

def review_rules(filename, bytes)
  text = bytes.dup.force_encoding(Encoding::UTF_8)
  raise "source comparison requires decoded UTF-8 text" unless text.valid_encoding? && !text.include?("\0")
  if filename.end_with?(".yaml", ".yml")
    document = YAML.safe_load(text, aliases: false)
    raise "expected string payload array" unless document.is_a?(Hash) && document["payload"].is_a?(Array) && document["payload"].all? { |rule| rule.is_a?(String) }
    rules = document["payload"].map(&:strip)
  else
    rules = text.lines.map(&:strip)
  end
  rules.reject! { |line| line.empty? || line.start_with?("#", ";", "//") }
  raise "no active rules" if rules.empty?
  # Accept domain-only lists as well as classical rule payloads, never binary data.
  domain_set = rules.none? { |line| line.include?(",") }
  check_rule_lines(rules, domain_set: domain_set)
  rules.map do |rule|
    if domain_set
      "#{rule.start_with?('.') ? 'DOMAIN-SUFFIX' : 'DOMAIN'},#{rule.delete_prefix('.')}"
    else
      rule.split(",").map(&:strip).join(",")
    end
  end.uniq
end

def scope_risks(rule)
  kind, value = rule.split(",", 3)
  kind = kind.upcase
  value = value.downcase.delete_suffix(".")
  risks = []
  risks << "keyword/wildcard/regex scope" if kind.match?(/KEYWORD|WILDCARD|REGEX/)
  risks << "whole network or geographic scope" if %w[IP-ASN GEOIP].include?(kind)
  risks << "whole top-level domain" if %w[DOMAIN-SUFFIX HOST-SUFFIX].include?(kind) && !value.include?(".")
  shared_suffix = %w[DOMAIN-SUFFIX HOST-SUFFIX].include?(kind) && SHARED_SCOPE.any? { |parent| value.end_with?(".#{parent}") }
  risks << "shared service/CDN scope" if SHARED_SCOPE.include?(value) || shared_suffix
  risks << "client-specific or compound rule" if %w[PROCESS-NAME PROCESS-PATH USER-AGENT AND OR NOT].include?(kind)
  risks
end

def check_rule_lines(rules, domain_set: false)
  invalid = rules.find do |rule|
    if domain_set
      !rule.match?(/\A\.?(?:[[:alnum:]_-]+\.)+[[:alnum:]_-]+\.?\z/)
    else
      kind, value = rule.split(",", 3)
      !RULE_TYPES.include?(kind.to_s.upcase) || value.to_s.strip.empty?
    end
  end
  raise "invalid #{domain_set ? 'domain' : 'rule'} entry: #{invalid[0, 120]}" if invalid
end

def audit_payload(url, bytes, urls)
  raise "empty response" if bytes.empty?
  if url.end_with?(".mrs", ".mmdb", ".dat")
    # ponytail: signature checks only; native clients must decode binary providers.
    raise "invalid MRS zstd signature" if url.end_with?(".mrs") && !bytes.b.start_with?("\x28\xb5\x2f\xfd".b)
    raise "missing MMDB metadata marker" if url.end_with?(".mmdb") && !bytes.b.include?("\xab\xcd\xefMaxMind.com".b)
    return ["binary-unparsed", []]
  end

  text = bytes.dup.force_encoding(Encoding::UTF_8)
  raise "invalid UTF-8 response" unless text.valid_encoding?
  active = text.lines.map(&:strip).reject { |line| line.empty? || line.start_with?("#", ";", "//") }
  raise "no active rules" if active.empty?
  raise "HTML returned instead of rules" if text.match?(/<!doctype\s+html|<html[\s>]/i)
  problems = []
  if url.end_with?(".yaml", ".yml")
    document = YAML.safe_load(text, aliases: false)
    raise "expected nonempty string payload array" unless document.is_a?(Hash) && document["payload"].is_a?(Array) && !document["payload"].empty? && document["payload"].all? { |rule| rule.is_a?(String) && !rule.strip.empty? }
    check_rule_lines(document["payload"])
    count = document["payload"].size
  else
    check_rule_lines(active, domain_set: url.end_with?("_Domain.list"))
    count = active.size
  end

  if url.match?(%r{/rule/(?:Shadowrocket|Surge)/}) && !url.end_with?("_Domain.list")
    expected = text.scan(/^# DOMAIN(?:-SUFFIX)?: (\d+)/).flatten.sum(&:to_i)
    actual = active.count { |line| line.start_with?("DOMAIN,", "DOMAIN-SUFFIX,") }
    companion = url.sub(/\.list\z/, "_Domain.list")
    problems << "missing domain companion #{companion}" if expected > actual && !urls.include?(companion)
  end
  if url.match?(%r{/(?:OpenAI|Claude|Gemini)/})
    AI_SHARED_DEPENDENCIES.each do |domain|
      problems << "captures shared dependency #{domain}" if active.any? { |line| line.downcase.include?(domain) }
    end
  end
  if url == "https://anti-ad.net/surge.txt" && !(75_000..125_000).cover?(count)
    problems << "anti-AD count #{count} is outside the reviewed 75k-125k band"
  end
  [count, problems]
end

def audit_sources(urls)
  queue = Queue.new
  urls.each { |url| queue << url }
  results = []
  mutex = Mutex.new
  workers = [6, urls.length].min.times.map do
    Thread.new do
      loop do
        url = queue.pop(true)
        bytes = yield url
        active, problems = audit_payload(url, bytes, urls)
        mutex.synchronize { results << [url, bytes.bytesize, active, Digest::SHA256.hexdigest(bytes), problems] }
      rescue ThreadError
        break
      rescue StandardError => e
        mutex.synchronize { results << [url, nil, nil, nil, [e.message]] }
      end
    end
  end
  workers.each(&:join)
  results
end

if ARGV == ["--self-test"]
  raise "missed ASN scope" if scope_risks("IP-ASN,14061,no-resolve").empty?
  raise "missed TLD scope" if scope_risks("DOMAIN-SUFFIX,ai").empty?
  raise "missed shared scope" if scope_risks("DOMAIN,api.github.com").empty?
  %w[s3.amazonaws.com blob.core.windows.net githubusercontent.com].each do |domain|
    raise "missed shared tenant suffix" if scope_risks("DOMAIN-SUFFIX,#{domain}").empty?
  end
  raise "flagged exact dedicated tenant" unless scope_risks("DOMAIN,ppl-ai-file-upload.s3.amazonaws.com").empty?
  raise "flagged provider hostname" unless scope_risks("DOMAIN,api.githubcopilot.com").empty?
  raise "missed keyword scope" if scope_risks("DOMAIN-KEYWORD,github").empty?
  raise "changed domain-list meaning" unless review_rules("domains.list", ".example.com\nexample.org\n") == ["DOMAIN-SUFFIX,example.com", "DOMAIN,example.org"]
  url = "https://example.com/rule/Surge/Example/Example.list"
  split = "# DOMAIN: 1\nIP-CIDR,192.0.2.0/24,no-resolve\n"
  raise "missed split source" if audit_payload(url, split, [url]).last.empty?
  raise "rejected paired source" unless audit_payload(url, split, [url, url.sub(".list", "_Domain.list")]).last.empty?
  raise "wrong YAML count" unless audit_payload("https://example.com/rules.yaml", 'payload: ["DOMAIN,example.com"]', []).first == 1
  domain_url = "https://example.com/Example_Domain.list"
  raise "rejected valid domains" unless audit_payload(domain_url, "example.com\n.ads.example.com\n", []).first == 2
  [[url, ""], [url, "<html>blocked</html>"], [url, "Service unavailable"], [url, "DOMAIN,"], [domain_url, "DOMAIN,example.com"], ["https://example.com/rules.yaml", "message: unavailable"], ["https://example.com/rules.yaml", "payload: ['Service unavailable']"], ["https://example.com/rules.mrs", "not zstd"]].each do |source, body|
    rejected = false
    begin
      audit_payload(source, body, [])
    rescue StandardError
      rejected = true
    end
    raise "accepted invalid response: #{source}" unless rejected
  end
  samples = 18.times.to_h { |n| ["https://example.com/#{n}.yaml", "payload: ['DOMAIN,host#{n}.example']"] }
  results = audit_sources(samples.keys) { |source| Thread.pass; samples.fetch(source) }
  raise "lost parallel result" unless results.map(&:first).sort == samples.keys.sort
  results.each do |source, size, count, digest, problems|
    raise "parallel download attributed to wrong URL" unless size == samples.fetch(source).bytesize && count == 1 && digest == Digest::SHA256.hexdigest(samples.fetch(source)) && problems.empty?
  end
  puts "Remote audit self-checks passed (offline)."
  exit
end
if ARGV.first == "--compare" && ARGV.length == 3
  begin
    before, after = ARGV.drop(1).map { |filename| review_rules(filename, File.binread(filename)) }
    added, removed = after - before, before - after
    puts "Source comparison: #{added.length} added, #{removed.length} removed."
    removed.each { |rule| puts "- #{rule}" }
    added.each { |rule| puts "+ #{rule}" }
    risks = added.flat_map { |rule| scope_risks(rule).map { |risk| "#{risk}: #{rule}" } }
    risks << "relative rule order changed" unless (before & after) == (after & before)
    abort "Scope review required before updating the pin:\n#{risks.join("\n")}" unless risks.empty?
    puts "No flagged scope expansion. Review deletions, ownership, and rule order before updating the pin."
  rescue StandardError => e
    abort "Source comparison failed: #{e.message}"
  end
  exit
end
abort "Usage: ruby scripts/audit_remote_sources.rb [--self-test | --compare OLD_FILE NEW_FILE]" unless ARGV.empty?

urls = PATHS.flat_map do |path|
  File.readlines(File.join(ROOT, path)).reject { |line| line.strip.start_with?("#", ";", "//", "update-url =") }
      .flat_map { |line| line.scan(%r{https://[^\s,"']+}).map { |url| url.sub(/[)\]]+\z/, "") } }
end
urls.select! { |url| SOURCE_HOSTS.include?(URI(url).host) }
urls.uniq!

results = audit_sources(urls) do |url|
  URI.open(url, read_timeout: 30, open_timeout: 15, redirect: false, &:read)
end

failures = results.flat_map { |url, _, _, _, problems| problems.map { |problem| "#{url}: #{problem}" } }
results.sort.each do |url, size, active, digest, _|
  if size
    puts "#{size}\t#{active}\t#{digest[0, 12]}\t#{url}"
  else
    puts "ERROR\t-\t-\t#{url}"
  end
end

abort failures.join("\n") unless failures.empty?
puts "Remote source audit passed (#{results.length} unique URLs; binary decoding requires native client validation)."
