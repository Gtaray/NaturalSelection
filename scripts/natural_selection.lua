function onInit()
	Token.onClickRelease = onTokenClickRelease;
end

----------------------------------------------
-- ON CLICK
----------------------------------------------

function onTokenClickRelease(token, button, image)
	if token == nil or image == nil or button ~= 1 then
		return;
	end

	local aStackedTokens = self.getStackedTokens(token, image);

	if #aStackedTokens > 1 then
		return self.openTokenSelector(aStackedTokens, image);
	else
		self.closeTokenSelector();
	end
end

----------------------------------------------
-- HELPERS
----------------------------------------------

function getStackedTokens(token, image)
	local x, y = token.getPosition();
	local tokenId = token.getId();
	local tokens = image.getTokens();
	local aStackedTokens = {};

	table.insert(aStackedTokens, { data = token, ctnode = CombatManager.getCTFromToken(token) });
	
	for _,vToken in ipairs(tokens) do
		local ctnode = CombatManager.getCTFromToken(vToken);

		if ctnode and vToken.getId() ~= tokenId and self.isOverlapping(token, vToken, image) then
			table.insert(aStackedTokens, { data = vToken, ctnode = ctnode });
		end
	end

	return aStackedTokens;
end

function openTokenSelector(aStackedTokens, image)
	--image.clearSelectedTokens();

	local existingWindow = Interface.findWindow("token_selector", "");
	if existingWindow then
		existingWindow.close();
	end

	local window = Interface.openWindow("token_selector", "");
	window.setTokens(aStackedTokens);
	window.setTargetingMode(Input.isControlPressed());
	window.initialize();

	return window;
end

function isOwner(ctnode)
	local rActor = ActorManager.resolveActor(ctnode);
	return Session.IsHost or DB.isOwner(rActor.sCreatureNode)
end

function closeTokenSelector()
	local existingWindow = Interface.findWindow("token_selector", "");
	if existingWindow then
		existingWindow.close();
	end
end

function isOverlapping(token1, token2, image)
	local x, y = token1.getPosition();
	local x2, y2 = token2.getPosition();

	if image.getGridType() == "square" then
		local gridsize = image.getGridSize();

		-- Round up to nearest integer
		-- divide by two since we only need to use the scale to offset from the center of the token to the edges
		local s1 = (math.ceil(token1.getScale()) * gridsize) / 2; 
		local s2 = (math.ceil(token2.getScale()) * gridsize) / 2;

		return math.min(x + s1, x2 + s2) > math.max(x - s1, x2 - s2) and
			   math.min(y + s1, y2 + s2) > math.max(y - s1, y2 - s2)
	else
		return x == x2 and y == y2;
	end
end