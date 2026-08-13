---
name: mediawiki-cargo
description: Manage Cargo extension tables on MediaWiki wikis — create, recreate, and debug Cargo-backed templates and tables. Use when adding new Cargo templates, debugging missing tables, running cargoRecreateData, or when cargo queries return empty results for pages that should have data.
---

# MediaWiki Cargo Table Management

Managing `#cargo_declare` / `#cargo_store` templates and their backing
database tables on wikis running the Cargo extension.

---

## How Cargo tables get created

A Cargo table is created when a **template page** containing
`{{#cargo_declare:_table=TableName ...}}` is saved and parsed by
MediaWiki. The parser function:

1. Validates field names against SQL reserved keywords.
2. Creates the DB table (`cargo_*` tables).
3. Sets a `CargoTableName` **page property** on the template page
   (stored in `page_props`).

If step 1 fails (e.g. reserved keyword), the table is **never created**
and no error surfaces to the user — the page saves silently.

The `cargoRecreateData` maintenance script later uses this page property
to find which template owns a table.

---

## SQL reserved keywords — the #1 silent failure

Cargo rejects field names that are SQL keywords. The error only appears
when parsing `#cargo_declare` directly (e.g. via `parse-wikitext` MCP
or viewing the template page). Common offenders:

| Keyword | Safe alternative |
|---------|-----------------|
| `order` | `sort_order` |
| `group` | `group_name` |
| `key` | `key_name` |
| `status` | `item_status` (sometimes accepted, test first) |
| `index` | `row_index` |
| `user` | `username` |
| `rank` | `sort_rank` |

**Always test new templates** by rendering `#cargo_declare` via
`parse-wikitext` before assuming the table exists:

```
parse-wikitext(title="Template:MyTemplate",
  wikitext="{{#cargo_declare:_table=MyTable|field1=String|order=Integer}}")
```

If the output says *"cannot be used as a Cargo Field name, because it
is an SQL keyword"*, rename the field.

---

## Recreating tables — `cargoRecreateData.php`

Run via kubectl into a MediaWiki pod:

```sh
KUBECONFIG=~/.kube/glug-infra.yaml kubectl exec -n <namespace> <pod> -c mediawiki -- \
  php /var/www/html/extensions/Cargo/maintenance/cargoRecreateData.php \
  --table=<TableName>
```

### Flags

| Flag | Purpose |
|------|---------|
| `--table=<Name>` | Recreate one specific table (use this) |
| `--replacement` | Build into a swap table first (zero-downtime) |
| `--quiet` | Suppress countdown and progress |

### Known bug: duplicate key on `cargo_tables`

Running `cargoRecreateData` **without** `--table` (all tables) fails
with:

```
Duplicate entry '<TableName>' for key 'cargo_tables.cargo_tables_main_table'
```

This happens when the `cargo_tables` registry row already exists but
the data table was dropped. The script does `INSERT` instead of
`REPLACE`. **Workaround:** always use `--table=<Name>` per table.

---

## Step-by-step: adding a new Cargo template

### 1. Write the template with safe field names

```wikitext
<noinclude>{{#cargo_declare:_table=MyTable
|page_title=String
|year=Integer
|sort_order=Integer
}}</noinclude><includeonly>{{#cargo_store:_table=MyTable
|page_title={{{page_title|{{FULLPAGENAME}}}}}
|year={{{year|}}}
|sort_order={{{sort_order|0}}}
}}</includeonly>
```

### 2. Save the template page

Via MCP `create-page` or `update-page`. This triggers the parser which
creates the DB table and sets the `CargoTableName` page property.

### 3. Verify the table exists

```sh
# Via kubectl — list registered tables:
KUBECONFIG=~/.kube/glug-infra.yaml kubectl exec -n <ns> <pod> -c mediawiki -- \
  php /var/www/html/extensions/Cargo/maintenance/cargoRecreateData.php \
  --table=MyTable
# Should print "Recreating data for Cargo table MyTable..." not "not declared"
```

Or via MCP: `cargo-list-tables` — the new table name should appear.

### 4. If the table is NOT listed

The `#cargo_declare` parser function didn't fire (usually because a
field name is a reserved keyword). Diagnose with `parse-wikitext`:

```
parse-wikitext(title="Template:MyTemplate",
  wikitext="{{#cargo_declare:_table=MyTable|...fields...}}")
```

Check for SQL keyword errors in the HTML output, fix, re-save, re-verify.

### 5. Populate data from existing pages

After creating the table, run `cargoRecreateData` to backfill data from
all pages that call the template:

```sh
KUBECONFIG=~/.kube/glug-infra.yaml kubectl exec -n <ns> <pod> -c mediawiki -- \
  php /var/www/html/extensions/Cargo/maintenance/cargoRecreateData.php \
  --table=MyTable
```

Output like `Saving data for pages 1 to N that call this template...`
confirms rows were inserted.

### 6. Verify data via MCP

- `cargo-list-tables` — table should appear
- `cargo-query` (requires authenticated access) — query the table
- `get-page` (HTML) on a page that uses `{{#cargo_query: tables=MyTable ...}}` — rendered output shows data

---

## Troubleshooting

### "Table X is not declared in any template; skipping"

The `page_props` entry for `CargoTableName` is missing. The template
was either never saved with `#cargo_declare`, or the parser function
errored (usually SQL keyword). Fix the template and re-save.

### cargoRecreateData crashes mid-run (duplicate key)

Run with `--table=<Name>` for each table individually instead of
recreating all at once.

### Table exists but cargo-query returns empty

The table was created but no pages have been saved that call the
template with `{{#cargo_store}}`. Save (or re-save) a page that uses
the template, then run `cargoRecreateData --table=<Name>` to backfill.

### parse-wikitext shows no error but table not created

The `parse-wikitext` tool renders wikitext without saving — it doesn't
persist page properties or create DB tables. You must actually **save**
the template page (via `create-page` or `update-page`) for the table to
be created.

---

## Quick reference — MCP tools for Cargo

| Tool | Use |
|------|-----|
| `cargo-list-tables` | List all registered Cargo tables |
| `cargo-describe-table` | Show field names/types for a table |
| `cargo-query` | Run a `#cargo_query` (needs auth) |
| `parse-wikitext` | Render wikitext to test `#cargo_declare` errors |
| `get-page` (html) | View rendered page including `#cargo_query` output |
| `create-page` / `update-page` | Save templates/pages (triggers Cargo hooks) |
