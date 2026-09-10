# Maintenance

`shadowrocket.conf` is the source policy. Port its intent to each export using
that client's syntax. Preserve provider AI, narrow Apple, China, and final rule
order. Keep shared dependencies outside provider AI selectors and GitHub in
Developer Services.

Run:

```sh
ruby scripts/validate_configs.rb
ruby scripts/validate_soul_module.rb
ruby scripts/audit_remote_sources.rb --self-test
```

To check the modules you plan to enable together, pass their names as separate
arguments, for example `ruby scripts/validate_configs.rb adblock-core privacy-dns
apple-account apple-services` on one line. Conflicting DNS, IPv6, adblock, or
return-to-China variants fail this check. It doesn't inspect installed modules
or enforce their order in Shadowrocket.

Pass the enabled module names to check their combination, for example
`ruby scripts/validate_configs.rb adblock-core privacy-dns ipv6`.

Then run `ruby scripts/audit_remote_sources.rb` and each target client long
enough to parse providers. The weekly `audit-sources` workflow catches upstream
removals and unexpected content changes between edits. Repository sources are
pinned; review and update the commit IDs deliberately. The Aggressive anti-AD
feed remains mutable. Static checks alone do not date a client as verified.

Blackmatrix's split lists need both `RULE-SET` and `DOMAIN-SET` entries at the
same pinned revision and policy. See the upstream
[Advertising instructions](https://github.com/blackmatrix7/ios_rule_script/blob/4112f8e7b3a9f23c9ccf381beaa5931a36df3781/rule/Shadowrocket/Advertising/README.md)
and [Surge Apple instructions](https://github.com/blackmatrix7/ios_rule_script/blob/4112f8e7b3a9f23c9ccf381beaa5931a36df3781/rule/Surge/Apple/README.md).
Advertising already includes Privacy. Don't add it again to Core.

The remote audit excludes comments and the profile's self-update URL. It
rejects redirects, empty/HTML responses, invalid YAML payloads, and missing
domain companions. Binary sources get signature checks where available,
not a full decode; their output says `binary-unparsed`. Native loading is a
separate check. Domain ownership also needs review: `ai.com` is no longer an
OpenAI route in these profiles; see its [current site](https://ai.com/).

Record native tests with client/version, OS/device, network/date, source URL
and full commit ID, enabled modules, selected groups, and sanitized observations
for direct, proxy, reject, final, DNS, Apple, streaming, and client-specific
exceptions. Remove tokens, private node names, and account identifiers.

When adding a group or module, update the root module index, export policy maps,
and behavior matrix. Keep a pinned rollback URL and local copy of the last
tested profile.

## Recorded check: 2026-09-10

Local config/Soul checks and remote-audit self-tests passed. The live audit
fetched 114 sources through the workstation's configured HTTP proxy. The
unchanged-profile syntax check passed with mihomo 1.19.30 on macOS arm64.
A scratch startup downloaded all 25 providers without logged parse errors;
only listener bindings changed (mixed port disabled, DNS on an ephemeral
loopback port). No proxy subscription or TUN was enabled for that check.
Shadowrocket, Surge, Quantumult X, and Soul still need device/session tests.
