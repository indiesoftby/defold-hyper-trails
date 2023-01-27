components {
  id: "trail_maker"
  component: "/hyper_trails/trail_maker_new.script"
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
embedded_components {
  id: "mesh"
  type: "mesh"
  data: "material: \"/hyper_trails/materials_new/trail.material\"\n"
  "vertices: \"/hyper_trails/models/box.buffer\"\n"
  "primitive_type: PRIMITIVE_TRIANGLE_STRIP\n"
  ""
  position {
    x: 0.0
    y: -0.931
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
