![Hyper Trails Logo](docs/logo.png)

[![Build Status](https://travis-ci.com/indiesoftby/defold-hyper-trails.svg?branch=master)](https://travis-ci.com/indiesoftby/defold-hyper-trails) [![Latest Release](https://img.shields.io/github/release/indiesoftby/defold-hyper-trails.svg)](https://github.com/indiesoftby/defold-hyper-trails/releases)

# Hyper Trails

Easy to use and customizable trail effect for the [Defold](https://www.defold.com) game engine.

Support Defold 1.4.3 and newer, later does't support runtime create resources.

Feel free to ask questions: [the topic about this asset is on the Defold forum](https://forum.defold.com/t/hyper-trails-customizable-trail-effect/48986).

## Installation

You can use **Hyper Trails** in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your `game.project` file and in the dependencies field under project add:

https://github.com/indiesoftby/defold-hyper-trails/archive/master.zip

and

https://github.com/KorolevSoftware/defold-fast-posh-vector2stream/archive/refs/tags/beta_1.0.zip

Or point to the ZIP file of a [specific release](https://github.com/indiesoftby/defold-hyper-trails/releases).

## Usage

Using it in your 2D game is simple:

1. Add .zip as a [Defold library dependency](http://www.defold.com/manuals/libraries/) - see above.
2. Copy `trail_maker.script` and `trail_model.model` from `/hyper_trails/trail_mesh.mesh` into your game object.
3. Run your game and move the game object. Enjoy!

## Example App

See the demo game.project for examples of how to use Hyper Trails on its own.

🕹️ [Play demo online](https://indiesoftby.github.io/defold-hyper-trails/) 🕹️

## How Does It Work?

Hyper Trails use from create runtime resource (resource.create_buffer):
1. Create resource.
2. Make buffers and fill vertex date.
3. Primitive type must be Triangle Strip.

## Script `trail_maker`

### Properties

*⚠️ This doc is a work in progress ⚠️*

![Terminology](docs/trail.png)

* `use_world_position` (boolean) - Calculate object movement delta using `go.get_position` or `go.get_world_position`.
* `trail_width` (number)
* `trail_tint_color` (vector4)
* `segment_length_max` (number)
* `segment_length_min` (number)
* `points_count` (number) - any number.
* `points_limit` (number) - Set 0 to use all points (deprecation).
* `fade_tail_alpha` (number)
* `shrink_tail_width` (boolean)
* `shrink_length_per_sec` (number)
* `texture_tiling` (boolean)
* `trail_model_url` (url)
* `auto_update` (boolean) - Uncheck this and send the `update` message to the script instance to manually update the trail.

### Properties

* `texture0` is drawn on the trail.

## Known Issues

### Data Vertex

Each Hyper Trail uses and updates its own instance of data vertex. The vertex is used as an array for buffer stream. So:

1. Update vertex data.
2. Copy to CPU memory from [faststream](https://github.com/KorolevSoftware/defold-faststream).
3. Defold map CPU memory to GPU.

### Trail Position

Defold now has such [the update order](https://forum.defold.com/t/go-set-position-lag/47458/10?u=aglitchman) so a trail head position will always be lagging behind for:

1. Physics-based objects (see the picture below).
2. Objects animated using `go.animate()`. 

![Physics Update Order Problem](docs/update_order_physics.png)

**Tip:** use the `trail_maker.queue_late_update()` function to get rid of this issue. Disable the `Auto Update` property for the trail maker instance and check the ` demo/demo_physics.script` how to manually send `update` message to the trail maker script.

## Credits

Artsiom Trubchyk ([@aglitchman](https://github.com/aglitchman)) is the current Hyper Trails owner within Indiesoft and is responsible for the open source repository.

Dmitry Korolev ([@KorolevSoftware](https://github.com/KorolevSoftware)) is the Hyper Trails helper and developer within Streamtheater.

### License

MIT License.
