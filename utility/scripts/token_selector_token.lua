local ctnode;
local token;
local bTargetingMode = false;

function setData(tokendata, bTargeting)
	ctnode = tokendata.ctnode;
	token = tokendata.data

	bTargetingMode = bTargeting;
end

-- We need to allow everyone to select all tokens so they can bring them to the top to target
function onClickDown()
	return true;
end

function onClickRelease()
	local image = ImageManager.getImageControl(token);
	if not image then
		return true;
	end

	if Input.isControlPressed() or bTargetingMode then
		self.targetToken(image);
		self.bringTokenToTop();
	else
		self.selectToken(image, token);
		self.bringTokenToTop();
	end

	self.onTokenSelected();
	self.closeSelector();

	return true;
end

function onDrop(x, y, dragdata)
	self.bringTokenToTop()
	if TokenManager.onDrop(token, dragdata) then
		self.closeSelector();
	end
end

function onTokenSelected()
	if window.onTokenSelected then
		window.onTokenSelected(token);
	end
end

function isOwner()
	local rActor = ActorManager.resolveActor(ctnode);
	return Session.IsHost or DB.isOwner(rActor.sCreatureNode)
end

function closeSelector()
	local existingWindow = Interface.findWindow("token_selector", "");
	if existingWindow then
		existingWindow.close();
	end
end

function targetToken(image)
	for _, selected in ipairs(image.getSelectedTokens()) do
		local nodeSource = CombatManager.getCTFromToken(selected);
		if nodeSource then
			TargetingManager.toggleCTTarget(nodeSource, ctnode)
		end
	end
end

function selectToken(image)
	-- We only want to select a token if the owner is the one clicking it
	-- otherwise we leave the selection alone.
	if self.isOwner() then
		image.clearSelectedTokens();
		image.selectToken(token.getId(), true);
	end
end

function bringTokenToTop()
	-- Hacky hack to get the token to the top of the stack.
	local x, y = token.getPosition();
	token.setPosition(x + 1, y + 1);
	token.setPosition(x, y);
end