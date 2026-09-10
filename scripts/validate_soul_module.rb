#!/usr/bin/env ruby

root = File.expand_path("..", __dir__)
body = File.read(File.join(root, "modules/soul-ktv.module"))
sections = {}
current = nil
body.each_line do |raw|
  line = raw.strip
  next if line.empty? || line.start_with?("#", ";", "//")

  if line.match?(/^\[.*\]$/)
    current = line
    abort "Soul module: duplicate section #{line}" if sections.key?(current)
    sections[current] = []
  else
    abort "Soul module: entry outside a section" unless current
    sections[current] << line
  end
end

abort "Soul module: unexpected sections or global overrides" unless sections.keys.sort == ["[Proxy Group]", "[Rule]"]
abort "Soul module: shipped selector must only allow REJECT" unless sections["[Proxy Group]"] == ["🎤 Soul KTV = select,REJECT,select=0"]
expected_rules = %w[soulapp.cn soulapp.me].map { |domain| "DOMAIN-SUFFIX,#{domain},🎤 Soul KTV" }
abort "Soul module: unexpected domain scope or route" unless sections["[Rule]"].sort == expected_rules.sort

readme = File.read(File.join(root, "README.md"))
[
  "https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/soul-ktv.module",
  "https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/soul-ktv.module"
].each { |url| abort "Soul module: README import URL missing" unless readme.include?(url) }
abort "Soul module: base profile must not activate Soul routing" if File.read(File.join(root, "shadowrocket.conf")).match?(/soul-ktv\.module|🎤 Soul KTV/)

puts "Soul module checks passed (default REJECT; runtime unverified)."
