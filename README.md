![Hyper Trails Logo](docs/logo.png)

[![Build Status](https://travis-ci.com/indiesoftby/defold-hyper-trails.svg?branch=master)](https://travis-ci.com/indiesoftby/defold-hyper-trails) [![Latest Release](https://img.shields.io/github/release/indiesoftby/defold-hyper-trails.svg)](https://github.com/indiesoftby/defold-hyper-trails/releases)

# Hyper Trails

Easy to use and customizable trail effect for the [Defold](https://www.defold.com) game engine.

Feel free to ask questions: [the topic about this asset is on the Defold forum](https://forum.defold.com/t/hyper-trails-customizable-trail-effect/48986).

## Installation

You can use **Hyper Trails** in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your `game.project` file and in the dependencies field under project add:

https://github.com/indiesoftby/defold-hyper-trails/archive/master.zip

Or point to the ZIP file of a [specific release](https://github.com/indiesoftby/defold-hyper-trails/releases).

## Usage

Using it in your 2D game is simple:

1. Add .zip as a [Defold library dependency](http://www.defold.com/manuals/libraries/) - see above.
2. Copy `trail_maker.script` and `trail_model.model` from `/hyper_trails/hyper_trail_16.go` into your game object.
3. Run your game and move the game object. Enjoy!
4. *(Optional)* Create a custom [.texture_profile](https://www.defold.com/manuals/texture-profiles/) with *Premultiply alpha* turned off for the path `/hyper_trails/textures/data/` to have a nice preview for trails in the Defold IDE.

## Example App

See the demo game.project for examples of how to use Hyper Trails on its own.

🕹️ [Play demo online](https://indiesoftby.github.io/defold-hyper-trails/) 🕹️

## How Does It Work?

1. A 3d model of 15 quads is used, the positions of which are integers: 0,1,2..15.
2. The texture from `texture0` sampler is used as an array for a vertex shader.
3. The vertex shader transforms the vertices of this 3d model during rendering of a trail.

## Script `trail_maker`

### Properties

*⚠️ This doc is a work in progress ⚠️*

![Terminology](docs/trail.png)

* `use_world_position` (boolean) - Calculate object movement delta using `go.get_position` or `go.get_world_position`.
* `trail_width` (number)
* `trail_tint_color` (vector4)
* `segment_length_max` (number)
* `segment_length_min` (number)
* `points_count` (number) - 16, 32 or 64.
* `points_limit` (number) - Set 0 to use all points.
* `fade_tail_alpha` (number)
* `shrink_tail_width` (boolean)
* `shrink_length_per_sec` (number)
* `texture_tiling` (boolean)
* `trail_model_url` (url)
* `auto_update` (boolean) - Uncheck this and send the `update` message to the script instance to manually update the trail.

## Model `trail_model`

The vertex shader transforms the vertices of this 3d model during rendering of a trail.

Hyper Trails comes with three models: with 16, 32 and 64 points (i.e. 15, 31, 63 segments):

* `/hyper_trails/models/trail_16.dae` (16 points)
* `/hyper_trails/models/trail_32.dae` (32 points)
* `/hyper_trails/models/trail_64.dae` (64 points)

Don't forget to set `points_count` in `trail_maker.script` according to the selected model.

### Properties

* `texture0` is a data texture. For each trail in the collection, specify an **unique** `texture0` from `/hyper_trails/textures/data/`.
* `texture1` is drawn on the trail.

## FAQ

### Why don't you use uniform attributes to render a trail?

1. Defold does not allow you to specify an array as a uniform attribute for the vertex shader.
2. Defold does not allow you to use more than 16 uniform attributes, although the minimum OpenGL ES specs allow is *128* vec4 uniforms in the vertex shader.
3. WebGL and OpenGL ES do not allow you to make an array of these 16 uniform attributes because of this limitation: "Support for indexing array/vector/matrix with a non-constant is only mandated for non-sampler uniforms in the vertex shader".

## Known Issues

### Data Texture

Each Hyper Trail uses and updates its own instance of data texture. The texture is used as an array for vertex shader. So:

1. Preparing a texture and loading it into GPU memory requires a LOT of CPU time. Keep this in mind when deciding to add 5 or more trails to the collection.
2. Floats encoded in RGBA color with 4 values [0..1]. Due to the low accuracy of these floats, the maximum size of trail is 65535 pixels.
3. For each trail in the collection, specify an **unique** `texture0` for the `trail_model`.

### Trail Position

Defold now has such [the update order](https://forum.defold.com/t/go-set-position-lag/47458/10?u=aglitchman) so a trail head position will always be lagging behind for:

1. Physics-based objects (see the picture below).
2. Objects animated using `go.animate()`. 

![Physics Update Order Problem](docs/update_order_physics.png)

**Tip:** use the `trail_maker.queue_late_update()` function to get rid of this issue. Disable the `Auto Update` property for the trail maker instance and check the ` demo/demo_physics.script` how to manually send `update` message to the trail maker script.

## Credits

Artsiom Trubchyk ([@aglitchman](https://github.com/aglitchman)) is the current Hyper Trails owner within Indiesoft and is responsible for the open source repository.

### License

MIT License.
