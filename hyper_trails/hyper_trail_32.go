components {
  id: "trail_maker"
  component: "/hyper_trails/trail_maker.script"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
  properties {
    id: "points_count"
    value: "32.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "trail_model"
  type: "model"
  data: "mesh: \"/hyper_trails/models/trail_32.dae\"\n"
  "material: \"/hyper_trails/materials/trail.material\"\n"
  "textures: \"/hyper_trails/textures/data/texture0_1.png\"\n"
  "textures: \"/hyper_trails/textures/white.png\"\n"
  "skeleton: \"\"\n"
  "animations: \"\"\n"
  "default_animation: \"\"\n"
  "name: \"unnamed\"\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
