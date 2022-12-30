function isSquareOverlapping(token1, token2, image)
	local x, y = token1.getPosition();
	local x2, y2 = token2.getPosition();
	local gridsize = image.getGridSize();

	-- Round up to nearest integer
	-- divide by two since we only need to use the scale to offset from the center of the token to the edges
	local s1 = (math.ceil(token1.getScale()) * gridsize) / 2; 
	local s2 = (math.ceil(token2.getScale()) * gridsize) / 2;

	return math.min(x + s1, x2 + s2) > math.max(x - s1, x2 - s2) and
			math.min(y + s1, y2 + s2) > math.max(y - s1, y2 - s2)
end

function isHexagonOverlapping(token1, token2, image)
	local gridSize = image.getGridHexElementDimensions();
	local x, y = token1.getPosition();
	local s1 = token1.getScale() * (gridSize / 2) -- Distance from center point to the edge of the token's border

	local x2, y2 = token2.getPosition();
	local s2 = token2.getScale() * (gridSize / 2);

	-- Calculate distance between 
	local dx = math.max(x, x2) - math.min(x, x2);
	local dy = math.max(y, y2) - math.min(y, y2);
	local distance = math.sqrt(dx * dx + dy * dy)
	
	-- Return if the distance between the two tokens is less than the sum of half their size
	return distance < (s1 + s2);
end

function isOverlappingSimple(token1, token2)
	local x, y = token1.getPosition();
	local x2, y2 = token2.getPosition();
	return x == x2 and y == y2;
end