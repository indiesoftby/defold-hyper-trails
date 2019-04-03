<!---
![](docs/logo.png)
-->

[![Latest Release](https://img.shields.io/github/release/aglitchman/defold-hyper-trails.svg)](https://github.com/aglitchman/defold-hyper-trails/releases)

# Hyper Trails

Easy to use and customizable trail effect for the [Defold](https://www.defold.com) game engine.

## Installation

You can use **Hyper Trails** in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your `game.project` file and in the dependencies field under project add:

https://github.com/aglitchman/defold-hyper-trails/archive/master.zip

Or point to the ZIP file of a [specific release](https://github.com/aglitchman/defold-hyper-trails/releases).

## Usage

...

### trail_maker



### trail_model

Заранее подготовленная 3D-модель, вершины которой изменяются с помощью vertex shader и. В комплекте с Hyper Trails есть три модели: с 16, 32 и 64 точками.

## Configuration

Select the `trail_maker` script component attached to the `hyper_trail_16.go` to modify the properties:

...

## Messages

Используйте константы из модуля `hyper_trails.msgs` для отправки следующих сообщений game object или скрипту `trail_maker`.

### follow_target

`hyper_trails.msgs.FOLLOW_TARGET` hash("follow_target")
`hyper_trails.msgs.FOLLOW_POSITION` hash("follow_position")
`hyper_trails.msgs.RESET_POSITION` hash("reset_position")
`hyper_trails.msgs.DRAW_TRAIL` hash("draw_trail")

## Known Issues

1. Каждый Hyper Trail использует и обновляет свой экземпляр текстуры с данными. Загрузка текстуры в видеопамять требует много процессорного времени. Имейте это в виду, когда решите добавить 10 и больше Hyper Trail на экран.
2. Данные в вершинный шейдер передаются с помощью текстуры. Числа закодированы в RGBA цвет с помощью 4 значений [0..1]. Из-за этого страдает точность передаваемых значений и есть ограничение: максимальный размер Hyper Trail 65535 пикселей.
3. Для каждого Hyper Trail требуется уникальная текстура в канале texture0, которую он использует для данных. Поэтому указывайте уникальный файл texture0 для каждого Hyper Trail в коллекции.

## Roadmap

* Исправить баг с `pos_offset`.
* Перенести часть кода trail_maker.script в отдельный Lua модуль.
