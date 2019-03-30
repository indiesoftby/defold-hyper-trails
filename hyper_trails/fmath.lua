local M = {}

function M.encode_rgba_float(f)
	local u = math.floor(f * 65536.0) + 2147483648.0
	local x = bit.rshift(bit.band(u, 0xff000000), 24)
	local y = bit.rshift(bit.band(u, 0x00ff0000), 16)
	local z = bit.rshift(bit.band(u, 0x0000ff00), 8)
	local w = bit.band(u, 0x000000ff)
	return { x, y, z, w }
end

function M.decode_rgba_float(u)
	-- return (u[1] * 16777216.0 + u[2] * 65536.0 + u[3] * 256.0 + u[4] - 2147483648.0) / 65536.0;
	return 256.0 * u[1] + u[2] + 0.00390625 * u[3] + 0.0000152588 * u[4] - 32768.0;
end

function M.encode_rgba_float48(f)
	local u = math.floor(f * 16777216.0) + 140737488355328.0
	local i = bit.rshift(bit.band(u, 0xff0000000000), 40)
	local j = bit.rshift(bit.band(u, 0x00ff00000000), 32)
	local x = bit.rshift(bit.band(u, 0x0000ff000000), 24)
	local y = bit.rshift(bit.band(u, 0x000000ff0000), 16)
	local z = bit.rshift(bit.band(u, 0x00000000ff00), 8)
	local w =            bit.band(u, 0x0000000000ff)
	return { i, j, x, y, z, w }
end

function M.decode_rgba_float48(u)
	-- return (u[1] * 1099511627776.0 + u[2] * 4294967296.0 + u[3] * 16777216.0 + u[4] * 65536.0 + u[5] * 256.0 + u[6] - 140737488355328.0) / 16777216.0;
	return 65536.0 * u[1] + 256.0 * u[2] + u[3] + 0.00390625 * u[4] + 0.0000152588 * u[5] + 5.96046e-8 * u[6] - 8.38861e6;
end

return M