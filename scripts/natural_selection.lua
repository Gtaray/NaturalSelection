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

		if ctnode then
			local x2, y2 = vToken.getPosition()
			if x == x2 and y == y2 then
				-- We already added the selected token to the list, so don't add it here
				if vToken.getId() ~= tokenId then
					table.insert(aStackedTokens, { data = vToken, ctnode = ctnode });
				end
			end
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