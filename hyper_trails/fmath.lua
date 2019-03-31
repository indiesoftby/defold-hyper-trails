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

return M