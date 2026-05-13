# Creating a ClaudePet skin

ClaudePet draws the cat procedurally — every pose is code, not a sprite. So a "skin" is just a **palette**: a JSON file mapping ten named color slots to hex codes. No PNG art needed.

## Quickstart

1. Right-click the cat → **切换皮肤 → 打开社区皮肤文件夹…** (this creates `~/Library/Application Support/ClaudePet/skins/` if it doesn't exist).
2. Inside, create a folder per skin. The folder name is the skin id.
   ```
   ~/Library/Application Support/ClaudePet/skins/twilight/palette.json
   ```
3. Paste a `palette.json` (template below).
4. Restart ClaudePet (or re-open the skin menu — it re-scans on every open). Your skin appears in the **切换皮肤** submenu.

## palette.json schema

```json
{
  "displayName": "Twilight",
  "author": "@you",
  "license": "CC-BY-4.0",
  "colors": {
    "primary":      "#7B68EE",
    "primaryDark":  "#5547B0",
    "primaryLight": "#A89AF0",
    "belly":        "#F4F0FF",
    "cheek":        "#FFB3C8",
    "cheekDeep":    "#D8849E",
    "eye":          "#180E08",
    "highlight":    "#FFFFFF",
    "iris":         "#5FCC58",
    "accent":       "#F8C124"
  }
}
```

| Slot | Where it shows | Tip |
|---|---|---|
| `primary` | Body fur, head, ears, paws, tail | The dominant color of the cat |
| `primaryDark` | Stripes, shadows | Pick something noticeably darker than `primary` |
| `primaryLight` | Top-of-head highlight, tail tip | Lighter than `primary` |
| `belly` | Belly, paw pads | Cream / off-white usually reads "fur underbelly" |
| `cheek` | Cheek blush | Pink looks cute, skip if your skin is monotone |
| `cheekDeep` | Nose, mouth interior | Darker than `cheek` |
| `eye` | Eyeliner, mouth, paw outlines | Near-black; not pure black to avoid harshness |
| `highlight` | Eye glints, ZZZ text | White or very light tint |
| `iris` | Iris color (pet's eyes) | The single most personality-defining slot |
| `accent` | Spinning gear (when working), small details | A complementary color away from `primary` |

`displayName`, `author`, `license` are optional but encouraged. Hex format is `#RRGGBB` or `#RRGGBBAA`.

## Reference: built-in skins

| id | primary | iris | vibe |
|---|---|---|---|
| `mochi`  | `#E88748` | `#5ECA4F` | Original orange tabby (default) |
| `shadow` | `#4D4D57` | `#F5C72E` | Black cat with amber eyes |
| `snow`   | `#F5F5F7` | `#579EEB` | White cat with ice-blue eyes |

## Sharing your skin

For now skins are local-only. The `claude-pet-skins` community registry repo (P2) will accept palette PRs once it exists. In the meantime, share your `palette.json` in the discussion thread or as a Gist — the format is portable.

## Troubleshooting

- **Skin doesn't appear**: open the skin folder via the menu and confirm the layout is `<your-id>/palette.json` (one nested folder, not a bare json file).
- **Skin appears but cat looks broken / wrong**: a slot is missing. All ten slots are required. ClaudePet logs parse errors to stderr — `log stream --process ClaudePet` will surface them.
- **Chose the wrong color**: edit `palette.json` and re-pick the skin from the menu (no app restart needed for community skins, the menu rescans on each open).
