function calcOverlapSquare(token1, token2, image)
	local gridsize = MathHelpers.getImageGridSize(image);
	local overlapThreshold = NaturalSelection.getOverlapThresholdOption();

	local x, y = token1.getPosition();
	local s1 = (token1.getScale() * gridsize * overlapThreshold) / 2; 

	local x2, y2 = token2.getPosition();
	local s2 = (token2.getScale() * gridsize * overlapThreshold) / 2;

	return math.min(x + s1, x2 + s2) > math.max(x - s1, x2 - s2) and
			math.min(y + s1, y2 + s2) > math.max(y - s1, y2 - s2)
end

function calcOverlapCircle(token1, token2, image)
	local gridsize = MathHelpers.getImageGridSize(image);
	local overlapThreshold = NaturalSelection.getOverlapThresholdOption();

	local x, y = token1.getPosition();
	local s1 = (token1.getScale() * gridsize * overlapThreshold) / 2;  -- Distance from center point to the edge of the token's border

	local x2, y2 = token2.getPosition();
	local s2 = (token2.getScale() * gridsize * overlapThreshold) / 2;

	-- Calculate distance between 
	local dx = math.max(x, x2) - math.min(x, x2);
	local dy = math.max(y, y2) - math.min(y, y2);
	local distance = math.sqrt(dx * dx + dy * dy)
	
	-- Return if the distance between the two tokens is less than the sum of half their size
	return distance < (s1 + s2);
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