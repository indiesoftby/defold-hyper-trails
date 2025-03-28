components {
  id: "trail_maker"
  component: "/hyper_trails/trail_maker.script"
  properties {
    id: "trail_width"
    value: "15.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "trail_tint_color"
    value: "1.0, 1.0, 1.0, 1.0"
    type: PROPERTY_TYPE_VECTOR4
  }
  properties {
    id: "points_count"
    value: "20.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "fade_tail_alpha"
    value: "20.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "shrink_tail_width"
    value: "true"
    type: PROPERTY_TYPE_BOOLEAN
  }
  properties {
    id: "auto_update"
    value: "false"
    type: PROPERTY_TYPE_BOOLEAN
  }
}
components {
  id: "trail_mesh"
  component: "/hyper_trails/models/trail_mesh.mesh"
}
components {
  id: "follow_object"
  component: "/demo/example_factory_trail.script"
}
