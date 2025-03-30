--
-- Helper functions for trail_maker.script
--
-- 'self' is trail_maker.script instance or table of parameters (see `trails_from_factory` example script).
--
-- Properties:
--
-- * follow_object_id (hash) - ID of the game object to follow. If empty, uses the current object.
-- * absolute_position (bool) - If true, trail points are positioned relative to the last position of the object.
-- * use_world_position (bool) - If true, uses world position instead of local position for the followed object.
-- * trail_width (number) - Width of the trail in pixels.
-- * trail_tint_color (vector4) - Color and alpha of the trail (RGBA).
-- * segment_length_max (number) - Maximum length of a trail segment. If > 0, segments exceeding this length will be split.
-- * segment_length_min (number) - Minimum length of a trail segment. If > 0, segments shorter than this will be merged.
-- * points_count (number) - Total number of points in the trail.
-- * points_limit (number) - Maximum number of visible points (0 = all points visible).
-- * fade_tail_alpha (number) - Number of points to fade at the tail (0 = no fading).
-- * shrink_tail_width (bool) - If true, trail width decreases from head to tail.
-- * shrink_length_per_sec (number) - Rate at which the trail length shrinks per second (0 = no shrinking).
-- * texture_tiling (bool) - If true, texture repeats along the trail; if false, texture stretches.
-- * trail_mesh_url (hash) - URL to the mesh component used for rendering the trail.
--

local M = {}

-- local hyper_geometry = require("hyper_trails.geometry")

-- The path to the new resource for `resource.create_buffer` must be unique,
-- attempting to create a buffer with the same name as an existing resource will raise an error.
-- We use this module-scope variable to make buffer IDs unique.
local unique_buffer_id = 0

local EMPTY_HASH = hash("")
local EMPTY_TABLE = {}
local VECTOR3_EMPTY = vmath.vector3()
local VECTOR3_ONE = vmath.vector3(1)

--- Queue late update for trail rendering
--- Based on https://forum.defold.com/t/delay-when-using-draw-line-in-update/68695/2
function M.queue_late_update()
	-- DEPRECATED <!!!> the hack is not needed anymore, hasn't worked since Defold 1.2.196
	physics.raycast_async(VECTOR3_EMPTY, VECTOR3_ONE, EMPTY_TABLE) 
end

--- Draw the trail by encoding data to buffers and updating UV options
---@param self table Script instance
function M.draw_trail(self)
	M.encode_data_to_buffers(self)
	M.update_uv_opts(self)
end

--- Encode trail data into mesh buffers
---@param self table Script instance
function M.encode_data_to_buffers(self)
	local trail_point_position = vmath.vector3()
	local offset_by_float = 1
	local positions = {}
	local tints = {}
	local absolute_position = self.absolute_position
	for i = self._data_w, 1, -1 do 
		local point_data = self._data[i]
		local vertex_up   = trail_point_position + point_data.v_1
		local vertex_down = trail_point_position + point_data.v_2
		if absolute_position then
			vertex_up = vertex_up + self._last_pos
			vertex_down = vertex_down + self._last_pos
		end
		positions[offset_by_float + 0] = vertex_up
		positions[offset_by_float + 1] = vertex_down

		tints[offset_by_float + 0] = point_data.tint
		tints[offset_by_float + 1] = point_data.tint
		
		offset_by_float = offset_by_float + 2
		trail_point_position = trail_point_position + point_data.dpos -- next point position
	end
	faststream.set_table_raw(self.vertex_position_stream, positions)
	faststream.set_table_raw(self.vertex_tint_stream, tints)

	if not self.mesh_buffer_resource then
		unique_buffer_id = unique_buffer_id + 1
		local buffer_path = "/hyper_trails/trail_mesh_" .. unique_buffer_id .. ".bufferc"
		self.mesh_buffer_resource = resource.create_buffer(buffer_path, { buffer = self.mesh_buffer })
		go.set(self.trail_mesh_url, "vertices", self.mesh_buffer_resource)
	end
end

--- Fade the tail of the trail by decreasing the alpha value of the tail points
---@param self table Script instance
---@param dt number Delta time
---@param data_arr table Array of trail point data
---@param data_from number Starting index for fading
function M.fade_tail(self, dt, data_arr, data_from)
	local m = math.min(data_from + self.fade_tail_alpha - 1, self._data_w)
	local j = 0
	for i = data_from, m do
		local w = j / (m - data_from)
		if data_arr[i].tint.w > w then
			data_arr[i].tint.w = w
		end
		j = j + 1
	end
end

--- Update trail position and properties based on object movement
---@param self table Script instance
---@param dt number Delta time
function M.follow_position(self, dt)
	local data_arr = self._data

	local new_pos = M.get_position(self)
	local diff_pos = self._last_pos - new_pos
	self._last_pos = new_pos

	local prev_point, head_point = M.get_head_data_points(self)

	local new_point = nil
	local add_new_point = true
	if self.segment_length_min > 0 then 
		if head_point.dlength < self.segment_length_min then
			diff_pos = diff_pos + head_point.dpos
			add_new_point = false
			new_point = head_point
			head_point = prev_point
		end
	end

	if add_new_point then
		new_point = data_arr[1]
		-- shift data array in left direction by one position
		for i = 1, self._data_w - 1 do
			data_arr[i] = data_arr[i + 1]
		end
	end

	-- for i = 1, self._data_w do -- unused
	-- 	data_arr[i].lifetime = data_arr[i].lifetime + dt 
	-- end

	new_point.dpos = diff_pos
	new_point.dlength = vmath.length(diff_pos)
	new_point.angle = M.make_angle(diff_pos)
	new_point.tint = vmath.vector4(self.trail_tint_color)
	new_point.width = self.trail_width
	new_point.lifetime = 0
	new_point.prev = head_point
	M.make_vectors_from_angle(self, new_point)

	data_arr[self._data_w] = new_point

	M.split_segments_by_length(self)

	local data_limit = self._data_w
	if self.points_limit > 0 then
		data_limit = self.points_limit
	end
	local data_from = self._data_w - data_limit + 1

	if self.shrink_length_per_sec > 0 then
		M.shrink_length(self, dt, data_arr, data_from)
	end

	if self.fade_tail_alpha > 0 then
		M.fade_tail(self, dt, data_arr, data_from)
	end

	if self.shrink_tail_width then
		M.shrink_width(self, dt, data_from, data_arr, data_limit)
	end

	if data_from > 1 then
		M.pull_not_used_points(self, data_arr, data_from)
	end
end

--- Get the two points at the head of the trail
---@param self table Script instance
---@return table Previous head point
---@return table Current head point
function M.get_head_data_points(self)
	return self._data[self._data_w - 1], self._data[self._data_w]
end

--- Get current position of the trail object
---@param self table Script instance
---@return vector3 Current position
function M.get_position(self)
	local id = self.follow_object_id == EMPTY_HASH and "." or self.follow_object_id
	if self.use_world_position then
		local pos = go.get_world_position(id)
		local scale = go.get_world_scale(id)
		pos.x = pos.x / scale.x
		pos.y = pos.y / scale.y
		return pos
	else
		return go.get_position(id)
	end
end

--- Initialize trail data points
---@param self table Script instance
function M.init_data_points(self)
	self._data = {}

	for i = 1, self._data_w do
		local tint = vmath.vector4(self.trail_tint_color)
		tint.w = 0

		self._data[i] = {
			dpos = vmath.vector3(), -- vector3, difference between this and previous point
			dlength = 0, -- length of dpos
			angle = 0, -- radians
			tint = tint, -- vector4
			width = self.trail_width, -- trail width
			lifetime = 0, -- used for fading
			prev = self._data[i - 1] -- link to the previous point
		}
		M.make_vectors_from_angle(self, self._data[i])
	end
end

--- Initialize mesh buffers for trail rendering
---@param self table Script instance
function M.init_buffers(self)
	self.mesh_buffer = buffer.create(self.points_count * 2, {
		{ name = hash("position"), type = buffer.VALUE_TYPE_FLOAT32, count = 3 },
		{ name = hash("texcoord0"), type = buffer.VALUE_TYPE_FLOAT32, count = 2 },
		{ name = hash("tint"), type = buffer.VALUE_TYPE_FLOAT32, count = 4 },
	})

	if self.mesh_buffer_resource then
		resource.release(self.mesh_buffer_resource)
		self.mesh_buffer_resource = nil
	end

	self.vertex_position_stream = buffer.get_stream(self.mesh_buffer, "position")
	self.vertex_texcoord_stream = buffer.get_stream(self.mesh_buffer, "texcoord0")
	self.vertex_tint_stream = buffer.get_stream(self.mesh_buffer, "tint")

	local texcoord = {}
	for rev_index = self.points_count, 1, -1 do
		local new_y = (rev_index - 1)/(self.points_count - 1)
		table.insert(texcoord, 1)
		table.insert(texcoord, new_y)
		table.insert(texcoord, 0)
		table.insert(texcoord, new_y)
	end
	faststream.set_table_universal(self.vertex_texcoord_stream, texcoord)
end

--- Clean up resources on script destruction
---@param self table Script instance
function M.final(self)
	if self.mesh_buffer_resource then
		resource.release(self.mesh_buffer_resource)
	end
end

--- Initialize trail properties
---@param self table Script instance
function M.init_props(self)
	if self.points_limit > self.points_count then
		self.points_limit = self.points_count
	end
end

--- Initialize internal variables
---@param self table Script instance
function M.init_vars(self)
	self._data_w = self.points_count
	self._last_pos = M.get_position(self)
end

--- Calculate angle from position difference
---@param diff_pos vector3 Position difference vector
---@return number angle Angle in radians
function M.make_angle(diff_pos)
	return math.atan2(-diff_pos.y, -diff_pos.x)
end

--- Generate perpendicular vectors for trail width based on angle
---@param self table Script instance
---@param row table Trail point data row
function M.make_vectors_from_angle(self, row)
	local a = row.angle - math.pi / 2
	local w = row.width / 2

	local vector = vmath.vector3(math.cos(a), math.sin(a), 0) * w
	row.v_1 = vector
	row.v_2 = -vector

	-- Trying to prevent crossing the points
	-- TEMPORARILY DISABLED
	-- if row.prev ~= nil and row.prev.v_1 ~= nil then
	-- 	local prev = row.prev
	-- 	local intersects = hyper_geometry.lines_intersects(row.v_1, prev.v_1 + row.dpos, row.v_2, prev.v_2 + row.dpos, false)
	-- 	if intersects then
	-- 		local v = row.v_2
	-- 		row.v_2 = row.v_1
	-- 		row.v_1 = v
	-- 	end
	-- end
end

--- Fill with zeros unused trail points
---@param self table Script instance
---@param data_arr table Array of trail point data
---@param data_from number Starting index for unused points
function M.pull_not_used_points(self, data_arr, data_from)
	local last_point = data_arr[data_from]
	last_point.dpos.x = 0
	last_point.dpos.y = 0
	for i = 1, data_from - 1 do
		local d = data_arr[i]
		d.dpos.x = 0
		d.dpos.y = 0
		d.dlength = 0
		d.width = 0
		d.tint.w = 0
		M.make_vectors_from_angle(self, d)
	end
end

--- Shrink trail length over time
---@param self table Script instance
---@param dt number Delta time
---@param data_arr table Array of trail point data
---@param data_from number Starting index for shrinking
function M.shrink_length(self, dt, data_arr, data_from)
	local to_shrink = self.shrink_length_per_sec * dt
	for i = data_from + 1, self._data_w - 1 do
		local d = data_arr[i]
		if d.dlength ~= 0 then
			if d.dlength > to_shrink then
				d.dlength = d.dlength - to_shrink
				d.dpos = vmath.normalize(d.dpos) * d.dlength
				break
			else
				to_shrink = to_shrink - d.dlength
				d.dpos.x = 0
				d.dpos.y = 0
				d.dlength = 0
			end
		end
	end
end

--- Shrink trail width from head to tail
---@param self table Script instance
---@param dt number Delta time
---@param data_from number Starting index
---@param data_arr table Array of trail point data
---@param data_limit number Maximum points to process
function M.shrink_width(self, dt, data_from, data_arr, data_limit)
	local j = 1
	for i = data_from, self._data_w do
		data_arr[i].width = self.trail_width * (j / data_limit)
		M.make_vectors_from_angle(self, data_arr[i])
		j = j + 1
	end
end

--- Split trail segments that exceed maximum length
---@param self table Script instance
function M.split_segments_by_length(self)
	if not (self.segment_length_max > 0) then
		return
	end

	local data_arr = self._data
	local _, head_point = M.get_head_data_points(self)

	while head_point.dlength > self.segment_length_max do
		local next_dlength = head_point.dlength - self.segment_length_max
		local normal = vmath.normalize(head_point.dpos)

		head_point.dlength = self.segment_length_max
		head_point.dpos = normal * head_point.dlength

		local new_point = data_arr[1]
		-- shift data array in left direction by one position
		for i = 1, self._data_w - 1 do
			data_arr[i] = data_arr[i + 1]
		end

		new_point.dpos = normal * next_dlength
		new_point.dlength = next_dlength
		new_point.angle = M.make_angle(new_point.dpos)
		new_point.tint = vmath.vector4(self.trail_tint_color)
		new_point.width = self.trail_width
		new_point.lifetime = 0
		new_point.prev = head_point
		M.make_vectors_from_angle(self, new_point)

		data_arr[self._data_w] = new_point

		_, head_point = M.get_head_data_points(self)
	end
end

--- Update UV options for trail texture
---@param self table Script instance
function M.update_uv_opts(self)
	local uv_opts = vmath.vector4(0)
	
	if self.texture_tiling then
		uv_opts.x = self.points_count
	else
		uv_opts.x = 1
	end
	-- uv_opts.x - repeat texture count, yzw - unused
	go.set(self.trail_mesh_url, "uv_opts", uv_opts)
end

return M