![Hyper Trails Logo](docs/logo.png)

[![Latest Release](https://img.shields.io/github/release/indiesoftby/defold-hyper-trails.svg)](https://github.com/indiesoftby/defold-hyper-trails/releases)

# Hyper Trails

Easy to use and customizable trail effect for the [Defold](https://www.defold.com) game engine.

To draw a trail, Hyper Trails asset creates a buffer, sets the buffer to a mesh, updates the buffer on every frame update.

⚠️ Requires Defold 1.4.3 and newer. 

Feel free to ask questions: [the topic about this asset is on the Defold forum](https://forum.defold.com/t/hyper-trails-customizable-trail-effect/48986).

## Installation

You can use **Hyper Trails** in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your `game.project` file and add the links in the dependencies field under project:

* https://github.com/indiesoftby/defold-hyper-trails/archive/master.zip (or point to the ZIP file of a [specific release](https://github.com/indiesoftby/defold-hyper-trails/releases))
* https://github.com/KorolevSoftware/defold-faststream/archive/main.zip

## Usage

Using it in your 2D game is simple:

1. Add the components `/hyper_trails/trail_maker.script` and `/hyper_trails/models/trail_mesh.mesh` to your game object.
2. Run your game and move the game object. Enjoy!
3. Look at the `demo/demo_main.collection` for examples of how to use Hyper Trails. `trails_from_factory` is a good example of how to use the asset from code using a single controller script.

## Example App

See the demo game.project for examples of how to use Hyper Trails on its own.

🕹️ [View the demo online](https://indiesoftby.github.io/defold-hyper-trails/) 🕹️

## Settings

![Terminology](docs/trail.png)

Available options:

* `follow_object_id` <kbd>hash</kbd> - ID of the game object to follow. If empty, uses the current object.
* `absolute_position` <kbd>bool</kbd> - Default is `false`, i.e. we assume that the object with the trail has the same position as the followed object. If true, trail vertices in the mesh buffer are positioned relative to the last position of the object.
* `use_world_position` <kbd>bool</kbd> - Default is `false`. If true, uses world position instead of local position for the followed object.
* `trail_width` <kbd>number</kbd> - Width of the trail in pixels.
* `trail_tint_color` <kbd>vector4</kbd> - Color and alpha of the trail (RGBA).
* `segment_length_max` <kbd>number</kbd> - Maximum length of a trail segment. If > 0, segments exceeding this length will be split.
* `segment_length_min` <kbd>number</kbd> - Minimum length of a trail segment. If > 0, segments shorter than this will be merged.
* `points_count` <kbd>number</kbd> - Total number of points in the trail.
* `points_limit` <kbd>number</kbd> - Maximum number of visible points (0 = all points visible). DEPRECATED.
* `fade_tail_alpha` <kbd>number</kbd> - Number of points to fade at the tail (0 = no fading).
* `shrink_tail_width` <kbd>bool</kbd> - If true, trail width decreases from head to tail.
* `shrink_length_per_sec` <kbd>number</kbd> - Rate at which the trail length shrinks per second (0 = no shrinking).
* `texture_tiling` <kbd>bool</kbd> - If true, texture repeats along the trail; if false, texture stretches.
* `trail_mesh_url` <kbd>hash</kbd> - URL to the mesh component used for rendering the trail.
* *(only for trail_maker.script)* `auto_update` <kbd>bool</kbd> - Uncheck this and send the `update` message to the script instance to manually update the trail.

Change mesh's `texture0` to draw custom texture on the trail.

## Known Issues

### Trail Position Lag

Defold now has such [the update order](https://forum.defold.com/t/go-set-position-lag/47458/10?u=aglitchman) so a trail head position will always be lagging behind for:

1. Physics-based objects (see the picture below).
2. Objects animated using `go.animate()`. 

![Physics Update Order Problem](docs/update_order_physics.png)

> [!TIP]
> You can disable the `Auto Update` property for the trail maker instance and check the ` demo/demo_physics.script` how to manually send `update` message to the trail maker script.

> [!IMPORTANT]
> Vote for [https://github.com/defold/defold/issues/7277](the issue).

## Credits

Artsiom Trubchyk ([@aglitchman](https://github.com/aglitchman)) is the current Hyper Trails owner within Indiesoft and is responsible for the open source repository.

### Contributors

* Dmitry Korolev ([@KorolevSoftware](https://github.com/KorolevSoftware)) - rewrote the asset to use buffers and to create buffer resources dynamically in runtime.
* [@vbif1](https://github.com/vbif1) - various bug fixes.

### License

MIT License.
