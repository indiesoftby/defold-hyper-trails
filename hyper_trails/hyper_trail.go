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
  properties {
    id: "trail_width"
    value: "24.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "segment_length_max"
    value: "200.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "segment_length_min"
    value: "200.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "points_count"
    value: "4.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "points_limit"
    value: "0.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "texture_tiling"
    value: "false"
    type: PROPERTY_TYPE_BOOLEAN
  }
}
embedded_components {
  id: "trail_model"
  type: "mesh"
  data: "material: \"/hyper_trails/materials_new/trail.material\"\n"
  "vertices: \"/hyper_trails/models/trail_model.buffer\"\n"
  "textures: \"/demo/assets/images/logo_text_texture.png\"\n"
  "primitive_type: PRIMITIVE_TRIANGLE_STRIP\n"
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
