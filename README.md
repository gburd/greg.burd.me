# greg@burd.me

[![Netlify Status](https://api.netlify.com/api/v1/badges/ad74ef1c-a629-4b1e-b5bf-f913a3c73f0c/deploy-status)](https://app.netlify.com/sites/burd-me/deploys)

Personal site, built with [Zola](https://www.getzola.org/) and deployed on
Netlify. Inspired by <https://mat.services>.

## How publishing works

Netlify watches the GitHub mirror of this repo and rebuilds on every push:

| Branch / event              | Where it deploys                              | Drafts? |
| --------------------------- | --------------------------------------------- | ------- |
| push to `main`              | <https://greg.burd.me> (production)           | no      |
| push to any other branch    | `https://<branch>--burd-me.netlify.app`       | yes     |
| open a pull request         | `https://deploy-preview-<n>--burd-me.netlify.app` | yes |

Build configuration lives in [`netlify.toml`](./netlify.toml). Zola version is
pinned via `ZOLA_VERSION`.

### Typical workflow

```sh
# Draft a new post on a branch.
git checkout -b staging
$EDITOR content/posts/new-thing/index.md     # add `+++ draft = true` while WIP
git push origin staging                       # auto-deploys to staging URL

# When happy, merge to main.
git checkout main
git merge staging
git push origin main                          # auto-deploys to production
```

Drafts are marked with `draft = true` in the front matter; they appear on
branch deploys and previews but never on production.

## Local development

With Nix (recommended — gives you the pinned toolchain):

```sh
nix develop
zola serve --drafts        # http://127.0.0.1:1111
```

Without Nix, install [Zola](https://www.getzola.org/documentation/getting-started/installation/)
≥ 0.20 and run `zola serve --drafts`. Nothing else is required: fonts and
syntax files are committed to the tree.

### Adding images

Source images live alongside their post (`content/posts/<slug>/`) or in
`static/image/`. To get optimized WebP output, prefix the filename with `_`
(e.g. `_hero.png`) and run `optimize-images` from the dev shell — it writes
the optimized `hero.webp` next to it. Commit both the source and the optimized
output. (`_*.png`/`_*.svg` are ignored by Zola via `ignored_content` in
`config.toml`.)

## Repo / mirror setup (one-time)

The canonical repository is on Codeberg: `git@codeberg.org:gregburd/greg.burd.me.git`.
Netlify only integrates with GitHub/GitLab/Bitbucket/Azure DevOps, so we use
Codeberg's **Push Mirror** feature to keep a GitHub mirror in sync, and point
Netlify at the mirror.

1. Create an empty repo on GitHub: `gburd/greg.burd.me`.
2. On Codeberg: **Settings → Mirror Settings → Add Push Mirror**.
   Remote URL: `https://github.com/gburd/greg.burd.me.git`.
   Authorization: a GitHub PAT with `repo` scope.
   Sync interval: `8h` (or whatever — pushes also trigger a sync).
3. On Netlify: **Site configuration → Build & deploy → Link to a different
   repository → GitHub** and pick `gburd/greg.burd.me`. Production branch =
   `main`. Build settings come from `netlify.toml`; leave the UI fields blank.
4. **Site configuration → Domain management** — add `greg.burd.me`, point your
   apex/CNAME at Netlify, enable HTTPS.
5. **Site configuration → Build & deploy → Branch deploys** — set to "All" or
   add the specific branches you want auto-deployed (e.g. `staging`).

After that, all you do is push.

## Secrets

None in the repo. Netlify holds its own deploy machinery; no `NETLIFY_TOKEN`
or `NETLIFY_SITE_ID` is needed locally unless you want to use `netlify-cli`
for ad-hoc previews (`nix develop` provides the CLI).
