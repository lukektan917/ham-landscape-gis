# Publishing to ArcGIS Online

How the three GeoJSON layers in `data/geojson/` get from this repo onto the
hosted feature layers behind the Web Map and the Web Experience.

`CLAUDE.md` holds the traps worth knowing before you start. This file is the
procedure, and a record of how it was actually done.

## The layers

Three hosted feature layers in the `harvard-cga` organisation, owned by
`lut688_Harvard_CGA`:

| Layer item | Sublayer | Source file |
| --- | --- | --- |
| `objects_points_116` | `objects_points_116_points` (ID 0) | `data/geojson/objects_points.geojson` |
| `birthplace_points_116` | `birthplace_points_116_points` (ID 0) | `data/geojson/birthplace_points.geojson` |
| `flow_lines_116` | `flow_lines_116_lines` (ID 0) | `data/geojson/flow_lines.geojson` |

Item IDs are visible in the item URLs. They are not secrets; the layers'
sharing state is.

## Why the REST API and not the web UI

**ArcGIS Online's Data tab has no "select all".** Rows are selected one at a
time, which is unusable for clearing a layer of 70-odd features. "Overwrite
entire feature layer" is greyed out for these layers, and "Update data" routes
into the *create new item* wizard in some browsers — which would publish a
duplicate layer rather than replacing the data.

The supported way to empty a hosted feature layer is the Feature Service's own
`deleteFeatures` operation, called over HTTP. Esri exposes an HTML form for it
in the **ArcGIS REST Services Directory**, served at the endpoint itself, so no
scripting or token handling is needed — the browser session's sign-in carries
the authorisation.

## Clearing a layer: `deleteFeatures`

Open this URL while signed in to ArcGIS Online:

```
https://services<N>.arcgis.com/<org-id>/arcgis/rest/services/<layer>/FeatureServer/0/deleteFeatures
```

The service root is on the item's **Overview** page, bottom right; append
`/0/deleteFeatures` to it. The form that loads looks like this:

| Field | Value |
| --- | --- |
| Object IDs | *(leave blank)* |
| **Where** | **`1=1`** |
| Input Geometry | *(leave blank)* |
| Rollback on Failure | True |
| Return Delete Results | True |
| ASync | False |
| Format | HTML |

Then **Delete Features**. `1=1` matches every row, so this empties the layer.
It is a **POST** — the page says so, and that is deliberate: Esri will not
accept a destructive call as a GET with the parameters sitting in the URL.

This is irreversible. It deletes rows only: the layer item, its ID, its fields,
its symbology, its popups and every Web Map and Experience Builder binding all
survive untouched. That is the whole reason to empty and refill a layer rather
than publish a new one — a new item would break every binding.

If `/0/truncate` is offered on the layer it does the same thing faster and
resets the ObjectID sequence, but it is unavailable when the layer has sync
enabled or a view pointing at it. `deleteFeatures` always works.

## Refilling

1. **Create any new fields first.** Appending cannot create fields: if a field
   in the GeoJSON has no matching field on the layer, its values are dropped
   silently and the column arrives empty. A new text field also defaults to 255
   characters, which truncates without warning.
2. **Add features** from the file — item page → Update data → Add features.
3. **Recalculate `Date_DT`**, which is an ArcGIS-side date field and cannot
   survive a GeoJSON load.
4. **Add the unique index** on `objectnumber` if it isn't there. This requires
   the values to be distinct, which they now are.
5. **Disable editing and re-share.** Never use "public data collection" to get
   editing on a shared layer — it permits anonymous internet edits to a
   Harvard-hosted asset. Unshare, edit, re-share.

### `Date_DT`

Arcade, calculated from `date_mid`:

```
Date(Floor($feature.date_mid), 0, 1, 12, 0, 0)
```

Month `0` is January — Arcade months are zero-based. The `12` is noon: ArcGIS
renders in UTC and applies a local-mean-time offset to pre-1900 dates, so a
midnight 1 January displays as 31 December of the previous year. `date_mid` is
populated on every feature, so no null guard is needed.

## Record of the 2026-11-08 deployment

Rebuilding after the exhibition-catalogue work. The layers held 77 / 61 / 77
features from an earlier export; the pipeline now produces 74 / 61 / 74.

Fields created before loading:

| Layer | Field | Type |
| --- | --- | --- |
| `objects_points_116` | `date_mid` | Integer |
| `flow_lines_116` | `date_mid` | Integer |
| `birthplace_points_116` | `biography` | String, length 1000 |
| `birthplace_points_116` | `biography_life` | String, length 255 |

`biography` runs to 949 characters and 56 of its 61 rows exceed 255, so the
default length would have truncated nearly all of them.

Each layer was then emptied with `deleteFeatures` / `where=1=1` and refilled
from `data/geojson/`, followed by the `Date_DT` recalculation above.

Three corrections that had previously been made by hand in the layer are now in
the pipeline, so they survive a reload: the blank `culture` on Albertus
Brondgeest and Francis Towne, Paul Sandby's doubled `"British, English"`, and
the century-midpoint years for the 15 objects HAM dates only by century. As far
as is known, nothing remains that exists only in ArcGIS.
