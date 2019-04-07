local M = {}

local hyper_fmath = require("hyper_trails.fmath")
local hyper_geometry = require("hyper_trails.geometry")

--
-- Helper functions for trail_maker.script
--
-- 'self' = trail_maker.script instance
--

function M.create_texture(self)
	self._tex_buffer = buffer.create(self._tex_w * self._tex_h, { 
		{
			name = hash("rgba"), 
			type = buffer.VALUE_TYPE_UINT8, 
			count = 4
		}
	})
	self._tex_stream = buffer.get_stream(self._tex_buffer, hash("rgba"))
end

function M.draw_trail(self)
	M.encode_data_to_texture(self)
	M.update_uv_opts(self)
	M.update_texture(self)
end

function M.encode_data_to_texture(self)
	local p = vmath.vector3()

	for i = self._data_w, 1, -1 do
		local d = self._data[i]

		M.write_vectors(self, i, p + d.v_1, p + d.v_2)
		M.write_tint(self, i, d.tint)

		p = p + d.dpos
	end
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

	for i = 1, self._data_w do
		data_arr[i].lifetime = data_arr[i].lifetime + dt
	end

	new_point.dpos = diff_pos
	new_point.dlength = vmath.length(diff_pos)
	new_point.angle = M.make_angle(diff_pos)
	new_point.tint = vmath.vector4(self.trail_tint_color)
	new_point.width = self.trail_width
	new_point.lifetime = 0
	new_point.prev = head_point
	M.make_vectors_from_angle(self, new_point)

	data_arr[self._data_w] = new_point

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

function M.init_props(self)
	assert(bit.band(self.points_count, (self.points_count - 1)) == 0, "Points count should be 16, 32, 64 (power of two).")

	if self.points_limit > self.points_count then
		self.points_limit = self.points_count
	end
end

function M.init_vars(self)
	self._tex_h = 8
	self._tex_w = self.points_count
	self._data_w = self.points_count
	self._resource_path = go.get(self.trail_model_url, "texture0")
	self._tex_header = { 
		width = self._tex_w,
		height = self._tex_h,
		type = resource.TEXTURE_TYPE_2D,
		format = resource.TEXTURE_FORMAT_RGBA,
		num_mip_maps = 1
	}

	model.set_constant(self.trail_model_url, "tex_size", vmath.vector4(self._tex_w, self._tex_h, 0, 0))

	self._last_pos = M.get_position(self)
end

function M.make_angle(diff_pos)
	return math.atan2(-diff_pos.y, -diff_pos.x)
end

function M.make_vectors_from_angle(self, row)
	local a = row.angle - math.pi / 2
	local w = row.width / 2

	row.v_1 = vmath.vector3(math.cos(a) * w, math.sin(a) * w, 0)
	row.v_2 = vmath.vector3(math.cos(a + math.pi) * w, math.sin(a + math.pi) * w, 0)

	-- Trying to prevent crossing the points
	if row.prev ~= nil and row.prev.v1 ~= nil then
		local prev = row.prev
		local intersects = hyper_geometry.lines_intersects(row.v_1, prev.v_1 + row.dpos, row.v_2, prev.v_2 + row.dpos, false)
		if intersects then
			local v = row.v_2
			row.v_2 = row.v_1
			row.v_1 = v
		end
	end
end

--function M.reset_position(self, position)
--	for i = 1, self._data_w do
--		self._data[i].pos = vmath.vector3(position)
--		self._data[i].dirty = true
--	end
--end

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

function M.update_texture(self)
	resource.set_texture(self._resource_path, self._tex_header, self._tex_buffer)
end

function M.update_uv_opts(self)
	if self.texture_tiling then
		model.set_constant(self.trail_model_url, "uv_opts", vmath.vector4(1, 0, 1, 0))
	else
		model.set_constant(self.trail_model_url, "uv_opts", vmath.vector4(0, 1, self.points_count, 0))
	end
end

function M.write_tint(self, p_x, tint)
	local s = self._tex_stream
	local p_y = 5

	local i = (p_y - 1) * self._tex_w * 4 + (p_x - 1) * 4 + 1
	s[i + 0] = tint.x * 255
	s[i + 1] = tint.y * 255
	s[i + 2] = tint.z * 255
	s[i + 3] = tint.w * 255
end

function M.write_vectors(self, p_x, v_1, v_2)
	local s = self._tex_stream

	local i = (p_x - 1) * 4 + 1
	local u = hyper_fmath.encode_rgba_float(v_1.x)
	s[i + 0] = u[1]
	s[i + 1] = u[2]
	s[i + 2] = u[3]
	s[i + 3] = u[4]

	i = i + self._tex_w * 4
	u = hyper_fmath.encode_rgba_float(v_1.y)
	s[i + 0] = u[1]
	s[i + 1] = u[2]
	s[i + 2] = u[3]
	s[i + 3] = u[4]

	i = i + self._tex_w * 4
	u = hyper_fmath.encode_rgba_float(v_2.x)
	s[i + 0] = u[1]
	s[i + 1] = u[2]
	s[i + 2] = u[3]
	s[i + 3] = u[4]

	i = i + self._tex_w * 4
	u = hyper_fmath.encode_rgba_float(v_2.y)
	s[i + 0] = u[1]
	s[i + 1] = u[2]
	s[i + 2] = u[3]
	s[i + 3] = u[4]
end

return M