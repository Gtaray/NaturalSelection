OOB_MSGTYPE_NS_SENDTOKENTOTOP = "ns_tokentotop";
OOB_MSGTYPE_NS_SENDTOKENTOBOTTOM = "ns_tokentobottom";

function onInit()
	OptionsManager.registerOption2("NS_ENABLED", true, "option_header_natural_selection", "option_label_enabled", "option_entry_cycler",
			{ labels = "option_val_no", values = "no", baselabel = "option_val_yes", baseval = "yes", default = "yes" })
	OptionsManager.registerOption2("NS_SELECTOR_LOCATION", true, "option_header_natural_selection", "option_label_location", "option_entry_cycler",
			{ labels = "option_val_location_left|option_val_location_topleft|option_val_location_top|option_val_location_topright|option_val_location_right|option_val_location_bottomright|option_val_location_bottom|option_val_location_bottomleft", values = "left|topleft|top|topright|right|bottomright|bottom|bottomleft", baselabel = "option_val_location_center", baseval = "center", default = "topright" })
	OptionsManager.registerOption2("NS_SELECTOR_THRESHOLD", true, "option_header_natural_selection", "option_label_overlap_threshold", "option_entry_cycler",
			{ labels = "option_val_threshold_10|option_val_threshold_20|option_val_threshold_30|option_val_threshold_40|option_val_threshold_50|option_val_threshold_75|option_val_threshold_100", values = "10|20|30|40|50|75|100", baselabel = "option_val_threshold_disabled", baseval = "0", default = "0" })
	OptionsManager.registerOption2("NS_SQUARE_CALC", false, "option_header_natural_selection", "option_label_square_grid_calc", "option_entry_cycler",
			{ labels = "option_val_calc_square|option_val_calc_circle", values = "square|circle", baselabel = "option_val_calc_exact", baseval = "exact", default = "square" })
	OptionsManager.registerOption2("NS_HEX_CALC", false, "option_header_natural_selection", "option_label_hex_grid_calc", "option_entry_cycler",
			{ labels = "option_val_calc_square|option_val_calc_circle", values = "square|circle", baselabel = "option_val_calc_exact", baseval = "exact", default = "circle" })
	OptionsManager.registerOption2("NS_ISO_CALC", false, "option_header_natural_selection", "option_label_iso_grid_calc", "option_entry_cycler",
			{ labels = "option_val_calc_square|option_val_calc_circle", values = "square|circle", baselabel = "option_val_calc_exact", baseval = "exact", default = "exact" })
	OptionsManager.registerOption2("NS_SIZE_ROUNDING", true, "option_header_natural_selection", "option_label_size_rounding", "option_entry_cycler",
			{ labels = "option_val_no", values = "no", baselabel = "option_val_yes", baseval = "yes", default = "no" })
	OptionsManager.registerOption2("NS_INCLUDE_NON_CT", true, "option_header_natural_selection", "option_label_include_non_ct", "option_entry_cycler",
			{ labels = "option_val_no", values = "no", baselabel = "option_val_yes", baseval = "yes", default = "no" })
	OptionsManager.registerOption2("NS_EXPANDED_STACK", true, "option_header_natural_selection", "option_label_expanded_stack_detection", "option_entry_cycler",
			{ labels = "option_val_no", values = "no", baselabel = "option_val_yes", baseval = "yes", default = "yes" })
	OptionsManager.registerOption2("NS_WIDGET_LOCATION", true, "option_header_natural_selection", "option_label_widget_location", "option_entry_cycler",
			{ labels = "option_val_location_left|option_val_location_topleft|option_val_location_top|option_val_location_topright|option_val_location_right|option_val_location_bottomright|option_val_location_bottom|option_val_location_bottomleft", values = "left|topleft|top|topright|right|bottomright|bottom|bottomleft", baselabel = "option_val_location_center", baseval = "center", default = "topright" })
	OptionsManager.registerOption2("NS_WIDGET_ENABLED", true, "option_header_natural_selection", "option_label_widget_enable", "option_entry_cycler",
			{ labels = "option_val_no", values = "no", baselabel = "option_val_yes", baseval = "yes", default = "no" })
	OptionsManager.registerOption2("NS_HOVER_ENABLED", true, "option_header_natural_selection", "option_label_hover_enable", "option_entry_cycler",
			{ labels = "option_val_no", values = "no", baselabel = "option_val_yes", baseval = "yes", default = "no" })

	OptionsManager.registerCallback("NS_WIDGET_ENABLED", onWidgetEnabledUpdated)
	OptionsManager.registerCallback("NS_WIDGET_LOCATION", onWidgetLocationUpdated)

	
	local nThreshold = tonumber(OptionsManager.getOption("NS_SELECTOR_THRESHOLD"));
	if nThreshold % 10 ~= 0 and nThreshold ~= 75 then
		local newThreshold = MathHelpers.roundToNearestMultiple(nThreshold, 10);
		Debug.console("Natural Selection: Outdated threshold percent (" .. nThreshold .. "). Adjusting to " .. newThreshold);
		OptionsManager.setOption("NS_SELECTOR_THRESHOLD", tostring(newThreshold));
	end

	Token.onClickRelease = onTokenClickRelease;
	Token.onDragEnd = onTokenMoveEnd;
	Token.onWheel = onTokenWheel;
	Token.onHover = onHover;

	--TokenManager.registerWidgetSet("stack", { "stacked" })

	CombatManager.setCustomTurnStart(onTurnStart);

	Interface.addKeyedEventHandler("onWindowOpened", "imagewindow", NaturalSelection.initializeTokenWidgets);

	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_NS_SENDTOKENTOTOP, handleTokenToFrontOob);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_NS_SENDTOKENTOBOTTOM, handleTokenToBackOob);
end

function onTabletopClose()
	NaturalSelection.closeTokenSelector();
end

-- Close the selector every time the turn changes	
function onTurnStart(nodeCt)
	NaturalSelection.closeTokenSelector();
end

function initializeTokenWidgets(window)
	local aTokens = window.image.getTokens();
	if #aTokens > 1 then
		-- Initialize the widget for stacked tokens
		NaturalSelection.onTokenMoveEnd(aTokens[1]);
	end
end

----------------------------------------------
-- TOKEN Z-LAYERING OOBS
----------------------------------------------
function sendTokenToFrontOob(tokeninstance)
	local tokenImage = tokeninstance.getContainerNode();

	if not tokenImage then 
		return;
	end

	local msg = {
		type = OOB_MSGTYPE_NS_SENDTOKENTOTOP,
		sTokenImage = DB.getPath(tokenImage),
		nTokenId = tokeninstance.getId()
	};

	Comm.deliverOOBMessage(msg, "");
end

function handleTokenToFrontOob(msg)
	if not Session.IsHost then
		return;
	end

	local tokeninstance = Token.getToken(msg.sTokenImage, msg.nTokenId);
	if tokeninstance then
		tokeninstance.bringToFront();
	end
end

function sendTokenToBackOob(tokeninstance)
	local tokenImage = tokeninstance.getContainerNode();

	if not tokenImage then 
		return;
	end

	local msg = {
		type = OOB_MSGTYPE_NS_SENDTOKENTOBOTTOM,
		sTokenImage = DB.getPath(tokenImage),
		nTokenId = tokeninstance.getId()
	};

	Comm.deliverOOBMessage(msg, "");
end

function handleTokenToBackOob(msg)
	if not Session.IsHost then
		return;
	end

	local tokeninstance = Token.getToken(msg.sTokenImage, msg.nTokenId);
	if tokeninstance then
		tokeninstance.sendToBack();
	end
end

----------------------------------------------
-- TOKEN WIDGET MANAGEMENT
----------------------------------------------
function updateWidgetForTokens(aTokens, bStacked)
	for _, token in ipairs(aTokens) do
		local nodeCT = CombatManager.getCTFromToken(token);
		NaturalSelection.updateWidget(token, nodeCT, bStacked)
	end
end

function updateWidget(tokenCT, nodeCT, bStacked)
	if not tokenCT then
		return;
	end
	if not nodeCT then
		return;
	end

	local wStackWidget = tokenCT.findWidget("stack");

	-- If bStacked is nil, then we only want to update widget locations if they exist
	if bStacked == nil then
		bStacked = wStackWidget ~= nil;
	end

	if wStackWidget and not bStacked then
		tokenCT.deleteWidget("stack");
		wStackWidget = nil;
	elseif not wStackWidget and bStacked then
		-- Only add the widget if the option is enabled.
		if NaturalSelection.isStackWidgetEnabled() then
			local tWidget = {
				name = "stacked",
				icon = "stack",
			}
			wStackWidget = tokenCT.addBitmapWidget(tWidget);
		end
	end

	if wStackWidget then
		-- Scale the widget size based on the token's size so it is obvious.
		local nTokenWidth, nTokenHeight = tokenCT.getImageSize();
		local nTokenScale = tokenCT.getScale();
		local nActualWidth = nTokenWidth * nTokenScale;
		local nActualHeight = nTokenHeight * nTokenScale;
		-- local nWidgetSize = nActualWidth * 0.4;
		local nWidgetSize = 30;

		local sPosition = NaturalSelection.getWidgetLocationOption();
		local nWidgetX, nWidgetY = 0, 0;

		if sPosition == "left" then
			nWidgetX = nWidgetSize / 2;
			nWidgetY = 0;
		elseif sPosition == "top" then
			nWidgetX = 0
			nWidgetY = nWidgetSize / 2;
		elseif sPosition == "right" then
			nWidgetX = -nWidgetSize / 2;
			nWidgetY = 0
		elseif sPosition == "bottom" then
			nWidgetX = 0
			nWidgetY = -nWidgetSize / 2;
		elseif sPosition == "topleft" then
			nWidgetX = nWidgetSize / 2;
			nWidgetY = nWidgetSize / 2;
		elseif sPosition == "topright" then
			nWidgetX = -nWidgetSize / 2;
			nWidgetY = nWidgetSize / 2;
		elseif sPosition == "bottomright" then
			nWidgetX = -nWidgetSize / 2;
			nWidgetY = -nWidgetSize / 2;
		elseif sPosition == "bottomleft" then
			nWidgetX = nWidgetSize / 2;
			nWidgetY = -nWidgetSize / 2;
		elseif sPosition == "center" then
			nWidgetX = 0;
			nWidgetY = 0;
		end

		wStackWidget.setBitmap("widget_stacked");
		wStackWidget.setTooltipText("Is stacked with other tokens");
		wStackWidget.setSize(nWidgetSize, nWidgetSize);
		wStackWidget.setPosition(sPosition, nWidgetX, nWidgetY);
	end
end

function onTokenWheel(tokenCT)
	NaturalSelection.onTokenMoveEnd(tokenCT);
end

function recalculateStackWidgets(image)
	local aTokens = image.getTokens()
	if #aTokens <= 1 then
		return;
	end

	NaturalSelection.onTokenMoveEnd(aTokens[1]);
end

----------------------------------------------
-- ON TOKEN MOVE
----------------------------------------------
function onTokenMoveEnd(token, dragdata)
	if not NaturalSelection.isStackWidgetEnabled() then
		return;
	end

	if not token then
		return;
	end

	local image = ImageManager.getImageControl(token);
	if not image then
		return;
	end

	-- Set up a dictionary here, which is much easier to handle than an array
	local aRemaining, nCount = NaturalSelection.getTokenDictionaryOrderedById(image.getTokens());
	if nCount <= 1 then
		return;
	end

	local aFinalStack = {};
	local aFinalUnstackedList = {};

	-- Iterate until every token has been checked
	-- We can bail if there's only one token remaining because there's no possible way it could stack with itself.
	while nCount > 0 do
		-- Grab the last token in the list and see what it is stacked with
		local key, currenttoken = NaturalSelection.getFirstInDictionary(aRemaining)
		local aChecked, nStackCount = NaturalSelection.getTokenDictionaryOrderedById(NaturalSelection.getStackedTokens(currenttoken));

		-- only add to the final list if there are multiple things in the stack
		local bAddToFinalStackList = nStackCount > 1;

		-- aChecked will always at least return 1 token, so we this will run even if there's nothing stacked with the token.
		for id, checkedtoken in pairs(aChecked) do
			if bAddToFinalStackList then
				table.insert(aFinalStack, checkedtoken)
			else
				table.insert(aFinalUnstackedList, checkedtoken)
			end

			-- Clear out tokens that have already been checked
			aRemaining[id] = nil;
			nCount = nCount - 1; 
		end
	end

	-- Now we have a list of all tokens on the image that are not stacked
	NaturalSelection.updateWidgetForTokens(aFinalStack, true);
	NaturalSelection.updateWidgetForTokens(aFinalUnstackedList, false);
end

function getTokenDictionaryOrderedById(aTokens)
	local aDictionary = {};
	local nCount = 0;

	for _, imagetoken in ipairs(aTokens) do
		local token = imagetoken;

		-- This accounts for the getStackedTokens function returning a data object and not an array of tokeninstance
		if imagetoken.data then
			token = imagetoken.data
		end

		aDictionary[token.getId()] = token;
		nCount = nCount + 1;
	end
	return aDictionary, nCount;
end

function getFirstInDictionary(aDictionary)
	for key, value in pairs(aDictionary) do
		return key, value;
	end
end

----------------------------------------------
-- ON CLICK
----------------------------------------------

function ProcessNaturalSelectionMenu(token, image)
	if not NaturalSelection.isEnabled() then
		return;
	end

	local aStackedTokens = NaturalSelection.getStackedTokens(token, image);

	if #aStackedTokens > 1 then
		return NaturalSelection.openTokenSelector(token, aStackedTokens, image);
	else
		NaturalSelection.closeTokenSelector();
		return;
	end
end

function onTokenClickRelease(token, button, image)
	-- Since double clicking tokens doesn't really work any more, we move that to middle mouse click
	if button == 2 then
		TokenManager.onDoubleClick(token, image);
		return;
	end

	if token == nil or image == nil or button ~= 1 then
		return;
	end

	if NaturalSelection.isHoverEnabled() then
		return;
	end
	
	ProcessNaturalSelectionMenu(token, image);
end

-- bring up token selector when hovering and bring down when not
function onHover(tokenMap, bOver)
	if not NaturalSelection.isHoverEnabled() then
		return;
	end
	ProcessNaturalSelectionMenu(tokenMap, ImageManager.getImageControl(tokenMap));
end

----------------------------------------------
-- GET STACKED TOKENS
----------------------------------------------

function getStackedTokens(token, image)
	if not image then
		image = ImageManager.getImageControl(token);
	end

	local x, y = token.getPosition();
	local tokenId = token.getId();
	local tokens = image.getTokens();
	local largestToken = token;
	local aStackedTokens = {};
	local aOtherTokens = {};
	local bIncludeNonCtTokens = NaturalSelection.includeNonCtTokens();

	if not bIncludeNonCtTokens then
		local selectedTokenCt = CombatManager.getCTFromToken(token)
		if not selectedTokenCt then
			return {};
		end
	end

	-- Store the single selected token so we can use it later
	local selectedToken = NaturalSelection.getSingleSelectedToken(image);
	
	for _,vToken in ipairs(tokens) do
		local bTokenVis, bForcedVisible = vToken.isVisible()

		-- We only care about tokens that are either visible, or if the user is the host
		if Session.IsHost or (bTokenVis and bForcedVisible ~= false) then
			local ctnode = CombatManager.getCTFromToken(vToken);

			-- First we want to ignore any tokens that aren't on the CT, unless the game setting specifically says to ignore that
			if ctnode or bIncludeNonCtTokens then
				-- Then we only care about tokens that are either the one that was clicked, or if it overlaps the one that was clicked.
				if tokenId == vToken.getId() or NaturalSelection.isOverlapping(token, vToken, image) then
					-- If the token is on the CT, grab some extra data from it
					local sFaction = nil;
					local bTargeted = false;

					if ctnode then
						sFaction = DB.getValue(ctnode, "friendfoe", "");

						-- "empty" is here because no faction on the CT is indicated by the ct_faction_empty
						if sFaction == "" then
							sFaction = "empty";
						end

						bTargeted = NaturalSelection.isTargeted(selectedToken, vToken);
					end

					-- Add the token to the list
					table.insert(aStackedTokens, { data = vToken, ctnode = ctnode, faction = sFaction, targeted = bTargeted });
					bAdded = true;

					-- save the token with the largest scale
					if vToken.getScale() > largestToken.getScale() then
						largestToken = vToken;
					end
				else
					-- Save these tokens for the next step, where we check for overlap again with the largest token in the stack
					table.insert(aOtherTokens, { data = vToken, ctnode = ctnode });
				end
				-- end overlap check
			end 
			-- end ct node or include non-ct tokens check
		end
		-- end session.host or token visibility echeck
	end
	-- end loop

	if OptionsManager.getOption("NS_EXPANDED_STACK") == "yes" then
		-- if the largest token in the stack is not the one that was selected, then go through and find everything under the largest token
		if largestToken.getId() ~= tokenId then
			for _,tokendata in ipairs(aOtherTokens) do
				if NaturalSelection.isOverlapping(largestToken, tokendata.data, image) then
					table.insert(aStackedTokens, tokendata);
				end
			end
		end
	end

	return aStackedTokens;
end

function isOverlapping(token1, token2, image)
	local sCalc = NaturalSelection.getGridCalcOption(image.getGridType())

	if sCalc == "square" then
		return MathHelpers.calcOverlapSquare(token1, token2, image);
	elseif sCalc == "circle" then
		return MathHelpers.calcOverlapCircle(token1, token2, image);
	elseif sCalc == "exact" then
		return MathHelpers.calcOverlapExact(token1, token2);
	end
end

function isTargeted(selectedToken, targetToken)
	if selectedToken == nil or targetToken == nil then
		return false;
	end

	return targetToken.isTargetedBy(selectedToken.getId());
end

function getSingleSelectedToken(image)
	local selectedTokens = image.getSelectedTokens();
	if #selectedTokens ~= 1 then
		return nil;
	end

	return selectedTokens[1];
end

----------------------------------------------
-- OPEN/CLOSE WINDOW
----------------------------------------------

function openTokenSelector(selectedToken, aStackedTokens, image)
	local existingWindow = Interface.findWindow("token_selector", "");
	if existingWindow then
		existingWindow.close();
	end

	local window = Interface.openWindow("token_selector", "");
	window.setTokens(aStackedTokens);

	if image.getGridType() == "square" then
		local _, _, imageScale = image.getViewpoint();
		local gridSize = image.getGridSize();
		window.setTokenSize(gridSize * imageScale)
	end
	window.initialize();

	NaturalSelection.placeWindow(window, image, selectedToken);

	return window;
end

function closeTokenSelector()
	local existingWindow = Interface.findWindow("token_selector", "");
	if existingWindow then
		existingWindow.close();
	end
end

--------------------------------------------------------------
-- WINDOW PLACEMENT
--------------------------------------------------------------

function placeWindow(window, image, token)
	local tx, ty = token.getPosition();
	local sX, sY = NaturalSelection.convertMapToScreenSpace(image, tx, ty);
	local width, height = window.getSize();
	local x, y;

	local sPosition = NaturalSelection.getWindowLocationOption();
	if sPosition == "left" then
		x, y = NaturalSelection.calculateWindowOffsets(image, token, sX, sY, -0.8, 0);
		y = y - (height / 2)
		x = x - width;
	elseif sPosition == "top" then
		x, y = NaturalSelection.calculateWindowOffsets(image, token, sX, sY, 0, -0.8);
		y = y - height
		x = x - (width / 2);
	elseif sPosition == "right" then
		x, y = NaturalSelection.calculateWindowOffsets(image, token, sX, sY, 0.8, 0);
		y = y - (height / 2)
	elseif sPosition == "bottom" then
		x, y = NaturalSelection.calculateWindowOffsets(image, token, sX, sY, 0, 0.8);
		x = x - (width / 2);
	elseif sPosition == "topleft" then
		x, y = NaturalSelection.calculateWindowOffsets(image, token, sX, sY, -0.8, -0.8);
		y = y - height;
		x = x - width;
	elseif sPosition == "topright" then
		x, y = NaturalSelection.calculateWindowOffsets(image, token, sX, sY, 0.8, -0.8);
		y = y - height;
	elseif sPosition == "bottomright" then
		x, y = NaturalSelection.calculateWindowOffsets(image, token, sX, sY, 0.8, 0.8);
	elseif sPosition == "bottomleft" then
		x, y = NaturalSelection.calculateWindowOffsets(image, token, sX, sY, -0.8, 0.8);
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

--------------------------------------------------------------
-- OPTIONS
--------------------------------------------------------------

function isEnabled()
	return OptionsManager.getOption("NS_ENABLED") == "yes";
end

function isHoverEnabled() 
	return OptionsManager.getOption("NS_HOVER_ENABLED") == "yes"
end

function getWindowLocationOption()
	return OptionsManager.getOption("NS_SELECTOR_LOCATION");
end

function getOverlapThresholdOption()
	return (tonumber(OptionsManager.getOption("NS_SELECTOR_THRESHOLD")) / 100);
end

function getGridCalcOption(sGridType)
	if sGridType == "square" then
		return NaturalSelection.getSquareGridCalcOption()
	elseif sGridType == "hexcolumn" or sGridType == "hexrow" then
		return NaturalSelection.getHexGridCalcOption();
	elseif sGridType == "iso" then
		return NaturalSelection.getIsoGridCalcOption();
	end

	-- DANGER! This should never happen, so default to the least permissive calc type
	return "exact";
end

function getSquareGridCalcOption()
	return OptionsManager.getOption("NS_SQUARE_CALC");
end

function getHexGridCalcOption()
	return OptionsManager.getOption("NS_HEX_CALC");
end

function getIsoGridCalcOption()
	return OptionsManager.getOption("NS_ISO_CALC");
end

function getTokenRounding()
	return OptionsManager.getOption("NS_SIZE_ROUNDING") == "yes";
end

function includeNonCtTokens()
	return OptionsManager.getOption("NS_INCLUDE_NON_CT") == "yes";
end

function isStackWidgetEnabled()
	return OptionsManager.getOption("NS_WIDGET_ENABLED") == "yes";
end

function getWidgetLocationOption()
	return OptionsManager.getOption("NS_WIDGET_LOCATION");
end