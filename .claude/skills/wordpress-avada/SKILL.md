---
name: wordpress-avada
description: WordPress operations focused on Avada theme + Avada Builder (Fusion Builder). Use for content updates, custom CSS, dynamic content setup, ACF integration, theme options, performance tuning. Covers REST API and WP-CLI patterns. Trigger when task references WordPress, Avada, Fusion Builder, or any WP page/post/template work.
---

# WordPress + Avada

## Scope

WordPress 6.x with Avada theme + Avada Builder. Common stack for SIDE clients and your own brand sites.

## Access patterns

Three ways to operate on WP:

1. **REST API** (preferred for content): `/wp-json/wp/v2/...`
2. **WP-CLI** (preferred for admin ops): `wp post update`, `wp option get`, etc.
3. **Direct DB** (last resort): only when REST/CLI can't reach it.

## Inputs

- Site URL (`WP_URL`)
- Application Password (`WP_USER`, `WP_APP_PASSWORD`)
- SSH access for WP-CLI (`WP_SSH_HOST`, key auth)

## Common operations

### Update post content

```
cdx "GOAL: Update WordPress post <post_id> on <WP_URL>.
NEW CONTENT: ./.scratch/post-content.html
ENDPOINT: POST /wp-json/wp/v2/posts/<post_id>
AUTH: Basic with WP_USER:WP_APP_PASSWORD
SUCCESS: post returns updated content, modified date current.
RETURN: STATUS + SUMMARY (post URL) + EVIDENCE (first 5 lines of returned content)."
```

### Bulk metadata update

```
cdx "GOAL: For all posts in category <slug>, update meta key 'fl_builder_data' nope -- update ACF field 'cta_text'.
INPUT: ./.scratch/cta-mapping.csv (post_id, new_cta)
METHOD: WP REST POST /wp-json/acf/v3/posts/<id>
RETURN: STATUS + SUMMARY (count updated, errored) + ARTIFACTS."
```

### Custom CSS via Avada theme options

Theme options live at `Avada → Options → Custom CSS` in admin OR `/wp-json/avada/v1/options/css` on newer Avada.

For programmatic update:
```
cdx "GOAL: Append CSS rule to Avada custom CSS option.
RULE: ./.scratch/new-rules.css
METHOD: WP-CLI: wp option get fusion_options --format=json | jq '.css += \"<rules>\"' | wp option update fusion_options --format=json
RETURN: STATUS + SUMMARY (option size before/after)."
```

### Avada Builder element insert

Avada Builder stores layouts as a custom post meta `fusion_builder_status` + the post content uses Fusion Builder shortcodes.

```
cdx "GOAL: Insert a Fusion Builder container with one column and a heading element into post <id>.
SHORTCODE TEMPLATE: ./.scratch/fusion-snippet.txt
METHOD: WP REST POST /wp-json/wp/v2/posts/<id> with content field updated.
NOTE: backups first - GET the post, save to ./.scratch/backup-post-<id>-$(date +%Y-%m-%d).html.
RETURN: STATUS + SUMMARY + EVIDENCE (URL preview)."
```

### Performance audit

```
cdx "GOAL: Audit Avada site <WP_URL> for common performance issues.
CHECKS:
  - Number of CSS files loaded on homepage (Avada combiner active?)
  - Number of JS files loaded
  - Images lacking lazy loading
  - Fonts: count + sources
  - Largest 10 assets
TOOL: Use python with httpx + parsel; or run lighthouse-cli.
OUTPUT: ./.scratch/avada-perf-$(date +%Y-%m-%d).json + a markdown summary
RETURN: STATUS + SUMMARY (top 5 issues) + ARTIFACTS."
```

## Avada-specific gotchas

- Fusion Builder content lives in post_content as shortcodes. Editing raw content can break the builder UI.
- Theme options stored in `wp_options` under `fusion_options`. Massive serialized array; back up before edits.
- Avada includes its own caching: Avada Performance → Asset Cleanup. Clear cache after major changes.
- Page templates: 100% Width vs Default. Affects header/footer rendering.
- Custom fonts: Avada → Options → Typography → Custom Fonts. Stored as paths in fusion_options.
- Form Builder (Avada Forms): submissions stored in `wp_fusion_form_submissions`.

## ACF integration

If the site uses ACF (Advanced Custom Fields):
- Read fields: `GET /wp-json/acf/v3/posts/<id>` (per-post) or `GET /wp-json/acf/v3/options/options` (option pages).
- Update fields: POST same endpoints.
- Field group definitions: in PHP code or local JSON sync.

## WP-CLI patterns

```bash
# Find posts referencing a deprecated shortcode
wp post list --post_type=post --post_status=publish --field=ID | xargs -I {} wp post get {} --field=post_content | grep -l 'old_shortcode'

# Bulk regen images
wp media regenerate --yes

# Search-replace (after migration)
wp search-replace 'oldsite.com' 'newsite.com' --all-tables --skip-columns=guid

# Plugin status
wp plugin list --status=active --format=csv
```

## Backup before any write

Before any post/option update, snapshot:

```
cdx "GOAL: Backup post <id> before edits.
SAVE: ./.scratch/backups/wp-post-<id>-$(date +%Y%m%d-%H%M).json
INCLUDE: full post object including meta and ACF.
RETURN: STATUS + SUMMARY (backup path)."
```

## Brand context

- SIDE's own site + most clients: Avada.
- Some clients on Divi or Elementor; this skill's principles apply, but selectors differ.

Voice for WP-delivered copy: brand voice from `CLAUDE.md`.

## Common pitfalls

- Editing `fusion_options` without unserialize-aware tool corrupts theme settings.
- WP-Cron disabled on staging but active on prod creates inconsistency.
- App passwords: must enable in user profile, format is `xxxx xxxx xxxx xxxx`.
- REST API can be disabled by security plugins (Wordfence, iThemes); ask user to whitelist.

## Anti-patterns

- Direct DB writes without backup.
- Bulk operations without rate limiting (some hosts will rate-limit you off).
- Storing app passwords in scratch files. Env only.
- Editing themes via FTP when WP-CLI works.
