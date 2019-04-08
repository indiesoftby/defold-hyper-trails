![Hyper Trails Logo](docs/logo.png)

[![Latest Release](https://img.shields.io/github/release/indiesoftby/defold-hyper-trails.svg)](https://github.com/indiesoftby/defold-hyper-trails/releases)

# Hyper Trails

Easy to use and customizable trail effect for the [Defold](https://www.defold.com) game engine.

## Installation

You can use **Hyper Trails** in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your `game.project` file and in the dependencies field under project add:

https://github.com/indiesoftby/defold-hyper-trails/archive/master.zip

Or point to the ZIP file of a [specific release](https://github.com/indiesoftby/defold-hyper-trails/releases).

## Usage

Using it in your 2D game is simple:

1. Add .zip as a [Defold library dependency](http://www.defold.com/manuals/libraries/) - see above.
2. Copy `trail_maker.script` and `trail_model.model` from `/hyper_trails/hyper_trail_16.go` into your game object.
3. Run your game and move the game object. Enjoy!

## How Trail Rendered

![Hyper Trails Logo](docs/trail.png)

1. Есть заранее подготовленная модель из 15 квадов (16 пар точек), позиции которых целые числа: 0,1,2..15. 
2. Есть текстура, которая используется в качестве массива данных. Данные кодируются в RGBA цвета.
3. Шейдер использует позиции из модели, данные из текстуры и формирует Hyper Trail.

Необходимо указать в Custom Resources игрового проекта путь к текстурам: /hyper_trails/textures/
Также (опционально) указать кастомный профиль текстур и исключить /hyper_trails/textures/ из premultiplied_alpha

## Script `trail_maker`



## Model `trail_model`

Заранее подготовленная 3D-модель, вершины которой изменяются с помощью vertex shader и. В комплекте с Hyper Trails есть три модели: с 16, 32 и 64 точками.

## Messages

Use the constants from the `hyper_trails.msgs` module to send the following messages to the `trail_maker` script:

1. 
2. 
3. 

## FAQ

### Why don't you use uniform attributes to render a trail?

1. Defold does not allow you to specify an array as a uniform attribute for the vertex shader.
2. Defold does not allow you to use more than 16 uniform attributes, although the minimum OpenGL ES specs allow is *128* vec4 uniforms in the vertex shader.
3. WebGL and OpenGL ES do not allow you to make an array of these 16 uniform attributes because of this limitation: "Support for indexing array/vector/matrix with a non-constant is only mandated for non-sampler uniforms in the vertex shader".

## Known Issues

Each Hyper Trail uses and updates its own instance of data texture. The texture is used as an array for vertex shader. So:

1. Preparing a texture and loading it into GPU memory requires a LOT of CPU time. Keep this in mind when deciding to add 5 or more Hyper Trails to the collection.
2. Floats encoded in RGBA color with 4 values [0..1]. Due to the low accuracy of these floats, the maximum size of Hyper Trail is 65535 pixels.
3. For each Hyper Trail in the collection, specify a unique `texture0` for the `trail_model`.

## Roadmap

* Исправить баг с `pos_offset`.
* Перенести часть кода trail_maker.script в отдельный Lua модуль.
