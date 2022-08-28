+++
title = "privacy notice"
path = "privacy"
+++

## summary

- no javascript or other client-side tracking is performed on this site.
- caddy server logs are enabled, but not persisted to disk.
- caddy server logs are aggregated into a self-hosted goatcounter instance for 180 days.
- the site is hosted by fly.io.

## data that i collect

### server logs

this site is served with caddy, and caddy's [default logging configuration](https://caddyserver.com/docs/caddyfile/directives/log) is used. caddy logs include information such as IP address, the document being requested, the time of request, and the response status from the server. caddy logs are not stored on disk, and are only retained for as long as the fly.io logging tooling can retrieve them.

#### statistics (goatcounter)

caddy logs are streamed to a self-hosted instance of [goatcounter](https://www.goatcounter.com). goatcounter aggregates logs to remove personal information. this instance of goatcounter is running on fly.io, and is completely unaffiliated with the goatcounter business - i operate the server myself. aggregated log data in goatcounter is retained for 180 days. the following statistics are aggregated:

- unique visitor sessions
  - "Track unique visitors for up to 8 hours"
- referrer + campaign
  - Referer header or utm_campaign/utm_source/ref
- screen size
- country
- language
  - "Supported languages from Accept-Language"

although it does not apply to the self hosted instance of goatcounter used by this site, the [hosted goatcounter instance's privacy policy](https://www.goatcounter.com/help/privacy) may be useful to review.

### site hosting

this site is hosted on fly.io. [see this page for fly.io's privacy statement](https://fly.io/legal/privacy-policy/).

## data that i share

logs and aggregated data are not shared with any third parties.
