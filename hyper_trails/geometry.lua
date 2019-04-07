local M = {}

--- Are two line segments in 2D space intersecting?
-- @author https://www.habrador.com/tutorials/math/5-line-line-intersection/
function M.lines_intersects(l1_p1, l1_p2, l2_p1, l2_p2, include_endpoints)
	-- To avoid floating point precision issues we can add a small value
	local epsilon = 0.00001

	-- Make sure the denominator is > 0, if not the lines are parallel
	local denominator = (l2_p2.y - l2_p1.y) * (l1_p2.x - l1_p1.x) - (l2_p2.x - l2_p1.x) * (l1_p2.y - l1_p1.y)
	if denominator ~= 0 then
		local u_a = ((l2_p2.x - l2_p1.x) * (l1_p1.y - l2_p1.y) - (l2_p2.y - l2_p1.y) * (l1_p1.x - l2_p1.x)) / denominator
		local u_b = ((l1_p2.x - l1_p1.x) * (l1_p1.y - l2_p1.y) - (l1_p2.y - l1_p1.y) * (l1_p1.x - l2_p1.x)) / denominator

		-- Are the line segments intersecting if the end points are the same
		if include_endpoints then
			-- Is intersecting if u_a and u_b are between 0 and 1 or exactly 0 or 1
			if u_a >= 0 + epsilon and u_a <= 1 - epsilon and u_b >= 0 + epsilon and u_b <= 1 - epsilon then
				return true
			end
		else
			-- Is intersecting if u_a and u_b are between 0 and 1
			if u_a > 0 + epsilon and u_a < 1 - epsilon and u_b > 0 + epsilon and u_b < 1 - epsilon then
				return true
			end
		end
	end

	return false
end

--- Performs a Catmull-Rom interpolation using the specified positions.
-- @param value1 The first position in the interpolation.
-- @param value2 The second position in the interpolation.
-- @param value3 The third position in the interpolation.
-- @param value4 The fourth position in the interpolation.
-- @param amount Weighting factor.
-- @return A position that is the result of the Catmull-Rom interpolation.
function M.catmull_rom(value1, value2, value3, value4, amount)
	local amount_sqr = amount * amount;
	local amount_cubed = amount_sqr * amount;
	return (
		0.5 *
		(((2.0 * value2 + (value3 - value1) * amount) +
		((2.0 * value1 - 5.0 * value2 + 4.0 * value3 - value4) * amount_sqr) +
		(3.0 * value2 - value1 - 3.0 * value3 + value4) * amount_cubed))
	);
end

--- Creates a new vector3 that contains Catmull-Rom interpolation of the specified vectors.
-- @param vector1 The first vector in interpolation.
-- @param vector2 The second vector in interpolation.
-- @param vector3 The third vector in interpolation.
-- @param vector4 The fourth vector in interpolation.
-- @param amount Weighting factor.
-- @return The result of Catmull-Rom interpolation.
function M.catmull_rom_vectors(vector1, vector2, vector3, vector4, amount)
	return vmath.vector3(
		M.catmull_rom(vector1.x, vector2.x, vector3.x, vector4.x, amount),
		M.catmull_rom(vector1.y, vector2.y, vector3.y, vector4.y, amount),
		M.catmull_rom(vector1.z, vector2.z, vector3.z, vector4.z, amount)
	)
end

return M