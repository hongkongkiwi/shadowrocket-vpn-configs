# Module recipes

Shadowrocket applies module rules before the base profile. Narrow Apple modules
must come before `apple-services`, the broad catch-all. Keep rejection modules
above `soul-ktv`, and Soul above either `back-to-cn` or `back-to-cn-all`.

Choose exactly one of `adblock-lite` and `adblock-core`. The base has no ad or
tracker block. Add `adblock-aggressive` only after Core and only when Core is
working. Choose at most one DNS module. `privacy-dns` uses Cloudflare and Quad9;
`dns-mainland-china` uses AliDNS and DNSPod. DoH endpoints are selected
concurrently by clients that support parallel resolver selection, rather than
being a guaranteed primary-then-fallback chain. Both Shadowrocket modules
intercept `*:53` and disable system and fallback-proxy DNS.

Safe Apple order:

```text
apple-certificate-validation
apple-account
apple-push
apple-updates
apple-siri-search
apple-intelligence
apple-app-downloads (when App Store/content needs its own route)
apple-services
```

The App Store CDN alias maps one host to a Kingsoft name. It is separate from
the App Downloads and Apple Updates routes.

## Hong Kong and travel

```text
adblock-core (or adblock-lite)
privacy-dns
private-ip-block (omit for split DNS/private services)
apple-certificate-validation
apple-account
apple-push
apple-updates
apple-siri-search (only when needed)
apple-intelligence (only when needed)
apple-services
```

Leave mainland DNS, `back-to-cn-all`, and the App Store CDN alias off. Add
`httpdns-block` or `real-ip-compat` only for a specific app failure. Choose
`ipv6` to enable IPv6 without preferring it. Use `ipv6-preferred` instead
only if the network and every chosen node pass IPv6 tests. `quic-compat` is
optional when a proxied app fails with QUIC.

Every base service selector has a manual `DIRECT` option. In Hong Kong, choose
it for services that work locally, without changing AI or streaming routes.
Existing proxy defaults are unchanged. `DIRECT` uses the current network and
does not provide a mainland IP when you're in Hong Kong.

## Mainland China

```text
adblock-core (or adblock-lite)
dns-mainland-china
apple-certificate-validation
apple-account
apple-push
apple-updates
apple-services
```

Start Apple Account and Apple Services on `DIRECT`. If that fails, hold one
Hong Kong node fixed and use `PROXY` for both throughout sign-in. Add
`apple-intelligence` above Services only when needed and select a working US
node. Keep `privacy-dns` and `back-to-cn` off. Use `china-app-tun-compat` only
for a listed mainland app that fails through the ordinary capture path.

## Apple Intelligence and PCC

Add `apple-siri-search` and `apple-intelligence` above `apple-services`.
The first covers Siri, dictation, and search and defaults to Direct. The second
covers Apple Intelligence Extensions plus Private Cloud Compute and starts with
the US selector. Keep one route fixed during account or device setup.
Certificate validation stays direct.

A regional `url-test` group can switch its chosen node. For a fixed session,
select one exact node through Shadowrocket's global `PROXY` selection and
choose `PROXY` in the relevant Apple groups, or use a private local module
with that node named directly. Neither an exit IP nor these rules establish
Apple Intelligence eligibility. Device, account region, OS, and language
requirements still apply; check [Apple's requirements](https://support.apple.com/en-us/121115).

The base policy splits OpenAI, Claude, and Google AI selectors and leaves shared
dependencies outside them. GitHub uses Developer Services. Streaming selectors
remain separate from AI.

Enable `ai-shared-dependencies` only if an AI sign-in or billing flow fails
because its shared services use a different exit. It also captures unrelated
apps that use Auth0, Stripe, Sentry, Intercom, and similar providers, so remove
it after diagnosis when possible.

## Back to China outside China

Start with the Hong Kong recipe, then add `back-to-cn`. It routes WeChat,
Alipay, Bilibili, NetEase Music, and mainland media rules to `🇨🇳 Return to
China`. Its selector exposes the automatic group plus matching individual
nodes; choose one individual node for account or payment sessions.

Leave both return modules disabled until you have a verified mainland node.
`CN` in a node name is only a filter match, not a location check. These general
travel selectors also expose `PROXY` and `DIRECT` as manual escape routes;
they do not enforce a mainland-only exit. For Soul, follow the separate
[reject-by-default setup](soul-ktv.md) instead. Its RTC and room-access tests
still require the mainland proxy you haven't configured yet.

Use `back-to-cn-all` instead when every mainland domain and IP should use the
mainland exit. Never enable both modules. Keep either one off while physically
in mainland China.

## Captive portal and DNS recovery

1. Disable the active DNS, private-answer, and HTTPDNS modules.
2. Keep `captive.apple.com` in the base `skip-proxy` setting.
3. Complete the network sign-in, then restore one DNS module.
4. For Apple sign-in, disable the CDN alias and use `DIRECT` for Account and
   Services; if needed, use one fixed Hong Kong node for both.

Never enable TLS decryption for Apple account, iCloud, push, certificate, or
update traffic.

## Local override example

Copy `examples/local-overrides.module.example` outside the repository, remove
the comment markers you need, and place it above shared modules. The ignored
name `local-overrides.module` is safe for a private working copy.

```ini
[Rule]
DOMAIN-SUFFIX,lan.example,DIRECT
DOMAIN,work.example,🌏 Foreign Websites
IP-CIDR,192.168.64.0/24,DIRECT,no-resolve
```
