function calcOverlapSquare(token1, token2, image)
	local gridsize = MathHelpers.getImageGridSize(image);
	local overlapThreshold = NaturalSelection.getOverlapThresholdOption();
	local bRoundToken = NaturalSelection.getTokenRounding();

	local x, y = token1.getPosition();
	local s1 = token1.getScale() * gridsize -- Token's pixel width

	local x2, y2 = token2.getPosition();
	local s2 = token2.getScale() * gridsize;

	if bRoundToken then
		s1 = MathHelpers.roundToNearestMultiple(s1, gridsize);
		s2 = MathHelpers.roundToNearestMultiple(s2, gridsize);
	end

	local o1 = s1 / 2; -- Offset to edge of token
	local o2 = s2 / 2;

	-- Calculate the difference between min and max x and y values, and if the difference along
	-- both axis is positive, then there's an overlap.
	local dx = math.min(x + o1, x2 + o2) - math.max(x - o1, x2 - o2);
	local dy = math.min(y + o1, y2 + o2) - math.max(y - o1, y2 - o2);

	-- If either of these deltas is below 0, then there's no overlap
	if dx < 0 or dy < 0 then
		return false;
	end

	local overlapArea = dx * dy; -- Can do this because it's a square
	local overlapPerc = math.max(overlapArea / (s1 * s1), overlapArea / (s2 * s2));

	return overlapPerc > overlapThreshold;
end

function calcOverlapCircle(token1, token2, image)
	local gridsize = MathHelpers.getImageGridSize(image);
	local overlapThreshold = NaturalSelection.getOverlapThresholdOption();

	local x, y = token1.getPosition();
	local r1 = (token1.getScale() * gridsize) / 2;  -- Distance from center point to the edge of the token's border

	local x2, y2 = token2.getPosition();
	local r2 = (token2.getScale() * gridsize) / 2;

	-- Calculate distance between 
	local dx = math.max(x, x2) - math.min(x, x2);
	local dy = math.max(y, y2) - math.min(y, y2);
	local distance = math.sqrt(dx * dx + dy * dy)

	local nonOverlapMinimum = r1 + r2; -- the minimum distance these tokens need to be to not overlap

	-- Return if the distance between the two tokens is less than the sum of half their size
	return distance < nonOverlapMinimum and distance / nonOverlapMinimum > overlapThreshold;
end

function calcOverlapExact(token1, token2)
	local x, y = token1.getPosition();
	local x2, y2 = token2.getPosition();
	return x == x2 and y == y2;
end

function getImageGridSize(image)
	local type = image.getGridType();
	if type == "square" then
		return image.getGridSize();
	elseif type == "hexcolumn" or type == "hexrow" then
		return image.getGridHexElementDimensions();
	else
		return image.getGridSize();
	end
end

function roundToNearestMultiple(nValue, nMultiple)
	return nValue + (nMultiple - (nValue % nMultiple));
end