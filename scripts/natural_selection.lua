function onInit()
	OptionsManager.registerOption2("SELECTOR_LOCATION", true, "option_header_natural_selection", "option_label_location", "option_entry_cycler",
			{ labels = "option_val_location_left|option_val_location_topleft|option_val_location_top|option_val_location_topright|option_val_location_right|option_val_location_bottomright|option_val_location_bottom|option_val_location_bottomleft", values = "left|topleft|top|topright|right|bottomright|bottom|bottomleft", baselabel = "option_val_location_center", baseval = "center", default = "topright" })

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
	local largestToken = token;
	local aStackedTokens = {};
	local aOtherTokens = {};

	table.insert(aStackedTokens, { data = token, ctnode = CombatManager.getCTFromToken(token) });
	
	for _,vToken in ipairs(tokens) do
		local ctnode = CombatManager.getCTFromToken(vToken);

		if ctnode and vToken.getId() ~= tokenId then
			if self.isOverlapping(token, vToken, image) then
				table.insert(aStackedTokens, { data = vToken, ctnode = ctnode });

				-- save the token with the largest scale
				if vToken.getScale() > largestToken.getScale() then
					largestToken = vToken;
				end
			else
				-- Save these tokens for the next step
				table.insert(aOtherTokens, { data = vToken, ctnode = ctnode });
			end
		end
	end

	-- if the largest token in the stack is not the one that was selected, then go through and find everything under the largest token
	if largestToken.getId() ~= tokenId then
		for _,tokendata in ipairs(aOtherTokens) do
			if self.isOverlapping(largestToken, tokendata.data, image) then
				table.insert(aStackedTokens, tokendata);
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

	if image.getGridType() == "square" then
		local _, _, imageScale = image.getViewpoint();
		local gridSize = image.getGridSize();
		window.setTokenSize(gridSize * imageScale)
	end
	window.initialize();

	self.placeWindow(window, image, aStackedTokens[1].data);

	return window;
end

function closeTokenSelector()
	local existingWindow = Interface.findWindow("token_selector", "");
	if existingWindow then
		existingWindow.close();
	end
end

function isOwner(ctnode)
	local rActor = ActorManager.resolveActor(ctnode);
	return Session.IsHost or DB.isOwner(rActor.sCreatureNode)
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

--------------------------------------------------------------
-- WINDOW PLACEMENT
--------------------------------------------------------------

function placeWindow(window, image, token)
	local tx, ty = token.getPosition();
	local sX, sY = self.convertMapToScreenSpace(image, tx, ty);
	local width, height = window.getSize();
	local x, y;

	local sPosition = self.getWindowLocationOption();
	if sPosition == "left" then
		x, y = self.calculateWindowOffsets(image, token, sX, sY, -0.8, 0);
		y = y - (height / 2)
		x = x - width;
	elseif sPosition == "top" then
		x, y = self.calculateWindowOffsets(image, token, sX, sY, 0, -0.8);
		y = y - height
		x = x - (width / 2);
	elseif sPosition == "right" then
		x, y = self.calculateWindowOffsets(image, token, sX, sY, 0.8, 0);
		y = y - (height / 2)
	elseif sPosition == "bottom" then
		x, y = self.calculateWindowOffsets(image, token, sX, sY, 0, 0.8);
		x = x - (width / 2);
	elseif sPosition == "topleft" then
		x, y = self.calculateWindowOffsets(image, token, sX, sY, -0.8, -0.8);
		y = y - height;
		x = x - width;
	elseif sPosition == "topright" then
		x, y = self.calculateWindowOffsets(image, token, sX, sY, 0.8, -0.8);
		y = y - height;
	elseif sPosition == "bottomright" then
		x, y = self.calculateWindowOffsets(image, token, sX, sY, 0.8, 0.8);
	elseif sPosition == "bottomleft" then
		x, y = self.calculateWindowOffsets(image, token, sX, sY, -0.8, 0.8);
		x = x - width;
	elseif sPosition == "center" then
		y = sY - height;
		x = sX - (width / 2);
	end

	window.setPosition(x, y, false);
end

function convertMapToScreenSpace(image, tokenX, tokenY)
	local imageWindowX, imageWindowY = image.window.getPosition();
	local imageControlX, imageControlY = image.getPosition();
	local imageControlW, imageControlH = image.getSize();
	local imageOriginX, imageOriginY, imageScale = image.getViewpoint();

	local imageCenterX = (imageWindowX + imageControlX) + (imageControlW / 2);
	local imageCenterY = (imageWindowY + imageControlY) + (imageControlH / 2);

	-- At this point, imageCenterX is the same screen point as imageOriginX, and imageCenterY is the same screen point as imageOriginY

	local tokenScreenX = ((tokenX - imageOriginX) * imageScale) + imageCenterX;
	local tokenScreenY = ((tokenY - imageOriginY) * imageScale) + imageCenterY;

	return tokenScreenX, tokenScreenY;
end

function calculateWindowOffsets(image, token, x, y,
	nHorizontalTokenPlacement, -- range 1 to -1. Scale factor for how far along the token's width to place the window
	nVerticalTokenPlacement) -- range 1 to -1. Scale factor for how far along the token's height to place the window

	local gridSize = image.getGridSize();
	local tokenScale = token.getScale();
	local _, _, imageScale = image.getViewpoint()
	local tokenPxSize = gridSize * tokenScale;

	local xOffset = ((tokenPxSize / 2) * imageScale) * nHorizontalTokenPlacement;
	local yOffset = ((tokenPxSize / 2) * imageScale) * nVerticalTokenPlacement;

	-- this moves it to the upper right corner
	return x + xOffset, y + yOffset;
end

function getWindowLocationOption()
	return OptionsManager.getOption("SELECTOR_LOCATION");
end