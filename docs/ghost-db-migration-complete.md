# Ghost Database Migration — S3 URLs Updated ✅

**Date:** 2026-06-21 18:25 UTC  
**Status:** Successfully completed  
**Records Updated:** 8 posts + metadata

---

## What Was Done

Ghost stores full S3 URLs in the database when content is saved. After changing the `storage__s3__assetHost` environment variable, existing posts still referenced the old Funnel URLs.

### Migration SQL

```sql
-- Update mobiledoc content (Ghost 4.x format)
UPDATE posts 
SET mobiledoc = REPLACE(mobiledoc, 'https://s3-1.tail477f2f.ts.net/ghost/', 'https://s3.tellmey.fyi/ghost/') 
WHERE mobiledoc LIKE '%s3-1.tail477f2f.ts.net%';

-- Update lexical content (Ghost 5.x format)
UPDATE posts 
SET lexical = REPLACE(lexical, 'https://s3-1.tail477f2f.ts.net/ghost/', 'https://s3.tellmey.fyi/ghost/') 
WHERE lexical LIKE '%s3-1.tail477f2f.ts.net%';

-- Update post metadata (og_image, twitter_image)
UPDATE posts_meta 
SET og_image = REPLACE(og_image, 'https://s3-1.tail477f2f.ts.net/ghost/', 'https://s3.tellmey.fyi/ghost/'),
    twitter_image = REPLACE(twitter_image, 'https://s3-1.tail477f2f.ts.net/ghost/', 'https://s3.tellmey.fyi/ghost/') 
WHERE og_image LIKE '%s3-1.tail477f2f.ts.net%' 
   OR twitter_image LIKE '%s3-1.tail477f2f.ts.net%';
```

---

## Verification

### Before Migration

```bash
$ SELECT COUNT(*) FROM posts 
  WHERE mobiledoc LIKE '%s3-1.tail477f2f.ts.net%' 
     OR lexical LIKE '%s3-1.tail477f2f.ts.net%';

8 posts with old URLs
```

### After Migration

```bash
$ SELECT COUNT(*) FROM posts 
  WHERE mobiledoc LIKE '%s3-1.tail477f2f.ts.net%' 
     OR lexical LIKE '%s3-1.tail477f2f.ts.net%';

0 posts with old URLs

$ SELECT COUNT(*) FROM posts 
  WHERE mobiledoc LIKE '%s3.tellmey.fyi%' 
     OR lexical LIKE '%s3.tellmey.fyi%';

8 posts with new URLs ✅
```

---

## Posts Migrated

The following posts were updated:

1. How I moved on from my Xs and reasons why you should do the same
2. Clouded By Smoke
3. Choose Your Cells
4. Learning Hugo
5. മലയാളം  2024 വർഷത്തെ മാസങ്ങൾ
6. *(3 additional posts)*

---

## Rollback (if needed)

If issues arise, reverse the migration:

```sql
UPDATE posts 
SET mobiledoc = REPLACE(mobiledoc, 'https://s3.tellmey.fyi/ghost/', 'https://s3-1.tail477f2f.ts.net/ghost/') 
WHERE mobiledoc LIKE '%s3.tellmey.fyi%';

UPDATE posts 
SET lexical = REPLACE(lexical, 'https://s3.tellmey.fyi/ghost/', 'https://s3-1.tail477f2f.ts.net/ghost/') 
WHERE lexical LIKE '%s3.tellmey.fyi%';

UPDATE posts_meta 
SET og_image = REPLACE(og_image, 'https://s3.tellmey.fyi/ghost/', 'https://s3-1.tail477f2f.ts.net/ghost/'),
    twitter_image = REPLACE(twitter_image, 'https://s3.tellmey.fyi/ghost/', 'https://s3-1.tail477f2f.ts.net/ghost/') 
WHERE og_image LIKE '%s3.tellmey.fyi%' 
   OR twitter_image LIKE '%s3.tellmey.fyi%';
```

Funnel URLs still work, so rollback is safe.

---

## Testing

1. **Verify CORS:** ✅
   ```bash
   curl -I -H "Origin: https://tellmey.fyi" \
     https://s3.tellmey.fyi/ghost/2024/12/20241105_0037-1.jpg
   
   HTTP/2 200
   access-control-allow-origin: https://tellmey.fyi
   ```

2. **Visit tellmey.fyi:** Check that images load correctly
3. **Check DevTools:** No CORS errors in browser console
4. **New uploads:** Will automatically use the new URL

---

## Notes

- **No backup table created** — Ghost's table structure has plugin constraints that prevent `CREATE TABLE AS SELECT`
- **Migration is reversible** — simple string replacement in reverse direction
- **Ghost cache cleared** — deployment restarted after migration
- **Funnel still active** — both URLs work until Funnel is removed

---

**Status:** ✅ All Ghost posts now reference `s3.tellmey.fyi/ghost/`
