# Soul KTV: mainland proxy required

This optional Shadowrocket module is prepared for a future mainland China
proxy. No mainland node is currently configured or verified for this task.
Leave the module disabled. It is not included in the base profile or the
client exports, and creating this file does not activate it in Shadowrocket.

Import URLs, available after this change is published:

- [Raw GitHub](https://raw.githubusercontent.com/hongkongkiwi/shadowrocket-vpn-configs/main/modules/soul-ktv.module)
- [jsDelivr](https://cdn.jsdelivr.net/gh/hongkongkiwi/shadowrocket-vpn-configs@main/modules/soul-ktv.module)

## Default behavior

The `🎤 Soul KTV` policy is a manual selector whose only shipped choice is
`REJECT`. If you enable it before setup, requests matching `soulapp.cn` or
`soulapp.me` are blocked. Disable the module to restore ordinary routing.
There is no automatic choice of `PROXY`, `DIRECT`, or a regional group.

These domain rules also affect ordinary Soul browsing and login. They cannot
isolate KTV within a shared host. They do not cover every possible Soul
connection, hard-coded IP, or third-party endpoint, and are not an app-wide
kill switch. Keep rejection modules above Soul and Soul above broader
back-to-China modules. Earlier rules can still win.

## Set up later

1. Obtain a proxy with a verified mainland China exit and working UDP relay.
   A node name containing `CN` is not evidence of its exit location. Confirm
   the provider allows Soul and real-time audio before paying.
2. Import the node into Shadowrocket. Make a local copy of this module so a
   remote refresh cannot overwrite your node selection configuration.
3. In that local copy, add the exact imported node name after `REJECT` in the
   `🎤 Soul KTV` selector. Keep `REJECT` first and keep `select=0`. Do not use an
   automatic region group or the generic `PROXY` choice.
4. Enable the local module and explicitly select that node. Inspect the
   connection log to confirm matched Soul traffic uses it. Hold that selection
   throughout the session. If the node is removed or expires, disable the
   module or select `REJECT` before further use.
5. Test room entry, listening, microphone audio, and singing. Compare the
   connections with ordinary Soul use and add only the dependencies observed
   during the test. Do not treat a successful IP lookup as proof that KTV works.

Soul lists Shengwang/Agora, Tencent TRTC, and other RTC SDKs in its
[third-party disclosure](https://themis.soulapp.cn/m/HZCSm0jfKDKi2BIrjspLfg.html).
Those SDK providers serve other apps too. Their shared domains and IP ranges
are deliberately absent until a session identifies which endpoints Soul uses.
Routing those endpoints and any QUIC compatibility changes need separate
testing. A domain rule alone does not establish UDP relay support.

A mainland exit changes the network address seen by the service. It does not
change device location or account eligibility. Soul describes IP and device
location processing in its
[privacy policy](https://themis.soulapp.cn/m/OyraGhrcJdj-RVlMC5d06A.html).
The exact KTV eligibility check, native module import, removed-node behavior,
room entry, and audio remain unverified.

## Local check

Run `ruby scripts/validate_soul_module.rb`. It checks the unconfigured reject
selection, bounded domain coverage, lack of global overrides, and README URLs.
It does not connect to a proxy or test Soul.
