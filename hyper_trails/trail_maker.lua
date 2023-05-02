--
-- Helper functions for trail_maker.script
--
-- 'self' is trail_maker.script instance
--

local M = {}

-- local hyper_geometry = require("hyper_trails.geometry")

-- The path to the new resource for `resource.create_buffer` must be unique,
-- attempting to create a buffer with the same name as an existing resource will raise an error.
-- We use this module-scope variable to make buffer IDs unique.
local unique_buffer_id = 0

local EMPTY_TABLE = {}
local VECTOR3_EMPTY = vmath.vector3()
local VECTOR3_ONE = vmath.vector3(1)

-- Based on https://forum.defold.com/t/delay-when-using-draw-line-in-update/68695/2
function M.queue_late_update()
	physics.raycast_async(VECTOR3_EMPTY, VECTOR3_ONE, EMPTY_TABLE) 
end

function M.draw_trail(self)
	M.encode_data_to_buffers(self)
	M.update_uv_opts(self)
end

function M.encode_data_to_buffers(self)
	local trail_point_position = vmath.vector3()
	local offset_by_float = 1
	local positions = {}
	local tints = {}
	for i = self._data_w, 1, -1 do 
		local point_data = self._data[i]
		local vertex_up   = trail_point_position + point_data.v_1
		local vertex_down = trail_point_position + point_data.v_2
		positions[offset_by_float + 0] = vertex_up
		positions[offset_by_float + 1] = vertex_down

		tints[offset_by_float + 0] = point_data.tint
		tints[offset_by_float + 1] = point_data.tint
		
		offset_by_float = offset_by_float + 2
		trail_point_position = trail_point_position + point_data.dpos -- next point position
	end
	faststream.set_table_raw(self.vertex_position_stream, positions)
	faststream.set_table_raw(self.vertex_tint_stream, tints)
end

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

function M.get_head_data_points(self)
	return self._data[self._data_w - 1], self._data[self._data_w]
end

function M.get_position(self)
	if self.use_world_position then
		local pos = go.get_world_position()
		local scale = go.get_world_scale()
		pos.x = pos.x / scale.x
		pos.y = pos.y / scale.y
		return pos
	else
		return go.get_position()
	end
end

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

function M.init_buffers(self)
	self.mesh_buffer = buffer.create(self.points_count * 2, {
		{ name = hash("position"), type = buffer.VALUE_TYPE_FLOAT32, count = 3 },
		{ name = hash("texcoord0"), type = buffer.VALUE_TYPE_FLOAT32, count = 2 },
		{ name = hash("tint"), type = buffer.VALUE_TYPE_FLOAT32, count = 4 },
	})

	if self.mesh_buffer_resource then
		resource.release(self.mesh_buffer_resource)
	end

	unique_buffer_id = unique_buffer_id + 1
	local buffer_path = "/hyper_trails/trail_mesh_" .. unique_buffer_id .. ".bufferc"

	self.mesh_buffer_resource = resource.create_buffer(buffer_path, { buffer = self.mesh_buffer })
	go.set(self.trail_mesh_url, "vertices", self.mesh_buffer_resource)

	self.vertex_position_stream = buffer.get_stream(self.mesh_buffer, "position")
	self.vertex_texcoord_stream = buffer.get_stream(self.mesh_buffer, "texcoord0")
	self.vertex_tint_stream = buffer.get_stream(self.mesh_buffer, "tint")

	local texcoord = {}
	for rev_index = self.points_count, 1, -1 do
		local new_y = (rev_index - 1)/(self.points_count - 1)
		local forw_index = self.points_count - rev_index + 1
		table.insert(texcoord, 1)
		table.insert(texcoord, new_y)
		table.insert(texcoord, 0)
		table.insert(texcoord, new_y)
	end
	faststream.set_table_universal(self.vertex_texcoord_stream, texcoord)
end

function M.final(self)
	if self.mesh_buffer_resource then
		resource.release(self.mesh_buffer_resource)
	end
end

function M.init_props(self)
	if self.points_limit > self.points_count then
		self.points_limit = self.points_count
	end
end

function M.init_vars(self)
	self._data_w = self.points_count
	self._last_pos = M.get_position(self)
end

function M.make_angle(diff_pos)
	return math.atan2(-diff_pos.y, -diff_pos.x)
end

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

function M.shrink_width(self, dt, data_from, data_arr, data_limit)
	local j = 1
	for i = data_from, self._data_w do
		data_arr[i].width = self.trail_width * (j / data_limit)
		M.make_vectors_from_angle(self, data_arr[i])
		j = j + 1
	end
end

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

-- uv_opts.x - repeat texture count, yzw - unused
function M.update_uv_opts(self)
	local uv_opts = vmath.vector4(0)
	
	if self.texture_tiling then
		uv_opts.x = self.points_count
	else
		uv_opts.x = 1
	end
	go.set(self.trail_mesh_url, "uv_opts", uv_opts)
end

return M