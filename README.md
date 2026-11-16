English | [日本語](README_jp.md)

# (Stable) Player Display 26.3

This is a port of [bradleyq/stable_player_display](https://github.com/bradleyq/stable_player_display) to **Minecraft Java Edition 26.3**, based on [erkko68's AJ-compatible fork (v1.4.1)](https://github.com/erkko68/stable_player_display).

It supports exports from Animated Java (AJ) 1.11.

## (NEW) Changes in This Fork

- **Improved entity rendering:** Replaced the fragile vertex-number mapping with UV-based mapping in `entity.vsh` and `entity.fsh` to address camera-angle stretching and reduce visual glitches.
- **Dynamic player skin support:** Added a function that lets an Animated Java player-display model use the skin of the player executing the function, without requiring a skin macro. See [Using the Animated Java sample datapack](#new-using-the-animated-java-sample-datapack) below.

## Verification Status

- Verified working in Minecraft Java Edition 26.3 with the [sample datapack](sample_datapack/), [standard resource pack](resourcepack/), and [split resource pack](resourcepack_split/).
- Animated Java compatibility has been verified using testing tools only.

## Included Files

| Path | Description |
| --- | --- |
| `resourcepack/` | Standard-model resource pack |
| `resourcepack_split/` | Split-model resource pack (includes elbows, waist, and knees) |
| `animated-java-resources/aj-convert.py` | Conversion script for Animated Java-exported datapacks |
| `animated-java-resources/player.ajblueprint` / `player_split.ajblueprint` | AJ blueprints (export target preset to 26.3) |
| `sample_datapack/` | Example player-display functions |
| `sample_datapack_for_aj/` | (NEW) Sample datapack with Animated Java skin-setting support |
| `animated-java-resources/tests/` | Tests for `aj-convert.py` |
| `tools/` | Build scripts and shader tests used during porting |

## Limitations

- Supports `item_display` entities only.
- **Do not change** a bone's `Rotation[1]` (pitch).
- Models break when placed **512 blocks or more above or below the player** (horizontal distance is unlimited).
- If you use `transformation.translation[1]` in animations, subtract the part's offset. When using AJ, `aj-convert.py` handles this automatically.
- Designed for vanilla Minecraft; modded environments are not supported.
- Incompatible with other resource packs that replace `core/entity.vsh` or `core/entity.fsh`.

## Resource Pack Installation

Enable **either** `resourcepack/` or `resourcepack_split/` as your resource pack. **Do not enable both.**

## How to Use

### (NEW) Using the Animated Java Sample Datapack

Use the [Animated Java sample datapack](sample_datapack_for_aj/) for the following features.

#### (NEW) Summoning an Animated Java Model

When summoning an Animated Java model, set the vertical rotation to `0` using `execute rotated ~ 0`:

```mcfunction
execute rotated ~ 0 run function aj:<project_name>/summon {args: {<input args here>}}
```

Replace `<project_name>` and `<input args here>` with the values for your AJ project.

#### (NEW) Setting the Player Skin Automatically

You no longer need to provide the player's skin through a macro when using `sample_datapack_for_aj/`. Instead, run the following function **as the player whose skin you want to use**:

```mcfunction
function pd:set_aj_skin
```

This updates the nearest Animated Java player-display model to use the skin of the player executing the function.

### Standard Sample Datapack

See the [standard sample datapack](sample_datapack/) for examples of the original player-display functions.

#### Settings

```mcfunction
data modify storage pd: _ set value {id:"example",name:"Alex",slim:true,split:true}
```

#### Summon

```mcfunction
function #pd:
```

#### Remove

```mcfunction
function pd:remove {id:"example"}
```

### Available Parameters in `_`

| Parameter | Description |
| --- | --- |
| `id` | ID of the player display (**required**) |
| `name` | Minecraft username whose skin is used (**optional**) |
| `slim` | Whether to use the slim model: `true` or `false` (default: `false`) |
| `split` | Whether to use the split model: `true` or `false` (default: `false`) |

For more details, see the [sample datapack](sample_datapack/).

## Slim Checker 26.3

You can check whether a player's skin uses the slim model with [Slim Checker](https://github.com/uma-channel/Slim-Checker-26.3).

## Animated Java: Datapack

The following instructions apply to **AJ 1.11 or later** (compatible with Minecraft 26.3).

1. Open `animated-java-resources/player.ajblueprint` (or `player_split.ajblueprint` for the split model) in AJ, then export it. Keep the Blueprint ID set to `aj:player_display`, as the tags and examples below assume this ID.

   **Conversion using "Use Storage for Animations" is now supported** (this was unsupported in v1.4.1).

2. Run the conversion script from the root of the exported datapack (next to the `data/` folder):

   ```bash
   python aj-convert.py aj:player_display -pn=jeb_
   python aj-convert.py aj:player_display -pn=jeb_ -split   # Split model
   python aj-convert.py aj:player_display --dry-run         # Preview without modifying files
   python aj-convert.py aj:player_display --force           # Force conversion, even if already converted
   ```

   | Option | Description |
   | --- | --- |
   | `-pn=NAME` | Player name whose skin is used. If omitted, items default to `air` (configured later in-game). |
   | `-split` | Applies offsets for the split model. |
   | `--dry-run` | Displays the target count without modifying files. |
   | `--force` | Runs conversion even if the export is already marked as converted. **Caution:** Avoid applying the conversion twice. |
   | `--tag-prefix P` | Specifies the tag prefix directly. By default, `:` and `/` in the Blueprint ID are replaced with `.`. |
   | `--datapack DIR` | Specifies the datapack root directory (default: current directory). |

   The script requires **Python 3.8 or later** and no longer depends on `nbtlib`, unlike older versions.

   If no conversion targets are found, the script stops with an error without overwriting files. After successful conversion, it creates `spd_aj_convert.json` in the datapack root to help prevent accidental re-execution on the same export.

3. Delete the resource pack exported by AJ. It is not needed; use the Player Display resource pack instead.

### Animated Java: Plugin Mode (Unsupported)

As with the original Stable Player Display, plugin-mode script conversion is unsupported. When importing the blueprint, manually add the Y-translation offsets listed below to the corresponding bones, set `item_display` to `thirdperson_righthand`, and configure `item_model`.

## Part Offsets

| Part | Y Offset |
| --- | ---: |
| head | 0 |
| right_arm | -1024 |
| left_arm | -2048 |
| torso | -3072 |
| right_leg | -4096 |
| left_leg | -5120 |
| right_forearm (Split) | -6144 |
| left_forearm (Split) | -7168 |
| waist (Split) | -8192 |
| lower_right_leg (Split) | -9216 |
| lower_left_leg (Split) | -10240 |

## Split Model

The split model adds arm and leg joints and an independent waist. Use `resourcepack_split/`, `player_split.ajblueprint`, and `aj-convert.py -split` **together as a set**.

## About AJ 1.11 Variants

The v1.4.1 README mentioned switching models using slim variants. In AJ 1.11 (for Minecraft 1.21.4 and later), **the current texture assigned to a texture slot is stored in `custom_model_data.strings`** on the bone item instead of the variant name.

As a result, switching variants does not change Stable Player Display's slim-model selection. Set the slim model through the loot tables described above (by setting `custom_model_data` directly) or through `item_model`.

## Troubleshooting

- **Model is invisible:** Make sure the resource pack is enabled, reload resources with `F3 + T`, and verify the `item_model` paths, `profile` (skin), `translation[1]` offsets, and `item_display: "thirdperson_righthand"` setting.
- **Model appears inverted or misplaced:** Check the item's `transformation` definition and confirm that `left_rotation` is set to `[1,0,0,0]`.
- **Body appears, but skin mapping is incorrect:** This fork uses UV-based mapping instead of vertex-number mapping. Confirm that you are using the updated `entity.vsh` and `entity.fsh` shaders, and submit a report with screenshots and steps to reproduce the issue if it persists.
- **Outer layer disappears or flickers:** This may be related to order-independent transparency (OIT) processing. Please submit a report with screenshots.
- **`aj-convert.py` stops with an error:** Read the error message. "No conversion targets found" can indicate that the Blueprint ID, tag prefix (`--tag-prefix`), or export format does not match the expected values.
- **"Already converted" message:** This is a safeguard against converting the same export twice. Run the script on a fresh AJ export.
- **Model distorts after editing pivots:** Manually adjust each part's `translation` in the resource pack.

## Submitting Reports

When reporting an issue, please include your AJ version, the commands and options you used, the full console log, and screenshots.

Please note that a response or resolution cannot be guaranteed.

## Credits and Licenses

- **[bradleyq](https://github.com/bradleyq/stable_player_display):** Original author
- **[erkko68](https://github.com/erkko68/stable_player_display):** AJ-compatible fork author
- **Resonance#3633:** Custom models and templates
- **[sireroo](https://github.com/sireroo):** Inspiration

See [LICENSE](LICENSE) for license details.
