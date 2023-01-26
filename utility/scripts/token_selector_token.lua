local ctnode;
local token;

function onInit()
	-- registerMenuItem(Interface.getString("menu_to_top"), "listinsert", 1);
	registerMenuItem(Interface.getString("menu_to_bottom"), "listinsert", 5);
end

function onMenuSelection(selection)
	if selection == 1 then
		-- onTokenSelected(true);
	elseif selection == 5 then
		onTokenSelected(false);
	end
end

function setData(tokendata, bTargeting)
	ctnode = tokendata.ctnode;
	token = tokendata.data
end

-- We need to allow everyone to select all tokens so they can bring them to the top to target
function onClickDown()
	return true;
end

function onClickRelease(button)
	-- Since double clicking tokens doesn't really work any more, we move that to middle mouse click
	if button == 2 then
		TokenManager.onDoubleClick(token, ImageManager.getImageControl(token));	
		NaturalSelection.closeTokenSelector();
		return;
	end

	self.onTokenSelected();
end

function onDrop(x, y, dragdata)
	window.onDroppedOnToken(token, dragdata);
end

function onTokenSelected(bTop)
	if window.onTokenSelected then
		window.onTokenSelected(token, ctnode, bTop);
	end
end