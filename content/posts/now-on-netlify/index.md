+++
title = "now on netlify"
date = "2022-10-16"
description = "a short update regarding me packing up my static site and moving from fly.io to netlify"
[taxonomies]
tags = ["static-site", "netlify"]
[extra]
hero = true
heroPrompt = "A man packing up and leaving home to move to the city, luggage and boxes outside of his house, a moving truck idling in his driveway, gorgeous illustration, high quality art, masterpiece"
+++

a short update today, and one that (unfortunately) obsoletes a lot of the work I put into [my last post on static site hosting](@/posts/static-site-with-nix-and-caddy/index.md): this site is now hosted on netlify! after [my most recent article](@/posts/command-line-flake-arguments/index.md) ran into some accessibility issues for people outside of my fly.io deployment region, I decided to minimize the moving parts involved in keeping the site running. i moved my static content over to [netlify](https://www.netlify.com/), a well-liked PaaS for deploying webapps and static sites (they also offer other things I don't care about, such as "Serverless" and FaaS offerings). [netlify's configuration file](https://docs.netlify.com/configure-builds/file-based-configuration/) supports all the same headers and redirects options that I was using in caddy, so the transition was extremely smooth.

fly.io is still running my goatcounter analytics instance, as well as my gitea instance, and I don't intend to stop using it for my other cloud deployment needs. ultimately, i didn't want to debug what could have been going wrong with the server on fly.io, nor did i want to think hard about scaling up into multiple regions or similar strategies. netlify seems like a good fit for straightforward and performant static site hosting.

my lingering quibble with netlify, along with many of the hosted PaaS and CI/CD solutions out there, is one of interoperability. in order to make use of continuous deployment functionality, virtually every one of these tools or platforms requires source code to be hosted on Github or Gitlab. this seems pretty arbitrary to me: couldn't most platforms just make use of git and webhooks directly? support could be easily extended then beyond Github and Gitlab to self managed git hosting instances, such as Gitea.

am I missing something obvious here?
