local MIN_CONTROL_SIZE = 50;
local CONTROL_SIZE = 50;
local PADDING = 4;
local MAX_PER_ROW = 3;
local MARGINS = 16;

local aTokens = {};
local height, width;

local tModifierKeys = { }

----------------------------
-- DATA INIT
----------------------------
function onInit()
	self.onSizeChanged = onSizeChanged;
	self.setModifierKey("shift", Input.isShiftPressed);
	self.setModifierKey("control", Input.isControlPressed);
	self.setModifierKey("alt", Input.isAltPressed);
end

function setTokens(tokens)
	aTokens = tokens;
end

function setModifierKey(sModifier, fGetFlag)
	if not sModifier or not fGetFlag then
		return;
	end
	
	sModifier = sModifier:lower();
	tModifierKeys[sModifier] = { bFlag = fGetFlag(), fGet = fGetFlag };
end

function setTokenSize(nSize)
	CONTROL_SIZE = nSize;
end

function initialize()
	-- First, get the smallest token image in the list so we can clamp
	-- the CONTROL_SIZE to that amount
	local nMinSize = math.huge;
	for index, token in ipairs(aTokens or {}) do
		local nSize = token.data.getImageSize();
		if nSize < nMinSize then
			nMinSize = nSize;
		end
	end	

	CONTROL_SIZE = math.max(MIN_CONTROL_SIZE, math.min(CONTROL_SIZE, nMinSize));

	self.calculateSize();
	setSize(width, height);

	local x = MARGINS / 2;
	
	for index, token in ipairs(aTokens or {}) do
		local nMaxSize = token.data.getImageSize();
		local col = (index - 1) % MAX_PER_ROW; -- -1 is to get the index back to being based on 0, not 1
		local row = math.floor((index - 1) / MAX_PER_ROW);

		local control = createControl("token_selector_token", "token_" .. index);
		control.setAnchor("left", "", "left", "absolute", (MARGINS / 2) + (col * CONTROL_SIZE) + ((col) * PADDING));
		control.setAnchor("top", "", "top", "absolute", (MARGINS / 2) + (row * CONTROL_SIZE) + ((row) * PADDING));
		control.setAnchoredWidth(CONTROL_SIZE, nMaxSize);
		control.setAnchoredHeight(CONTROL_SIZE);
		control.setPrototype(token.data.getPrototype());

		if token.faction then
			local widget = control.addBitmapWidget("ct_faction_" .. token.faction);
			if widget then
				widget.setSize(25, 25);
				widget.setPosition("topleft", 10, 12);
			end
		end

		if token.targeted then
			local widget = control.addBitmapWidget("drag_targeting");
			if widget then
				widget.setSize(25, 25);
				widget.setPosition("topright", -10, 10);
			end
		end

		if token.ctnode then
			local sTokenName = self.getTokenName(token.ctnode);
			control.setTooltipText(sTokenName);
		end

		control.setData(token, bTargetingMode);
		token.control = control;
	end
end

----------------------------
-- DATA GETS
----------------------------

function getTokenName(ctnode)
	if not ctnode then
		return "";
	end
	
	local rActor = ActorManager.resolveActor(ctnode);

	if Session.IsHost then
		return DB.getValue(ctnode, "name", "");
	else
		return ActorManager.resolveDisplayName(rActor);
	end
end

-- This gets either the stored flag (from when onInit() ran) or the current flag state
function getModifierKey(sModifier)
	if not sModifier then
		return false;
	end
	sModifier = sModifier:lower();

	local keydata = tModifierKeys[sModifier];
	if keydata == nil then
		return false;
	end

	return keydata.bFlag or keydata.fGet();
end

function isOwner(token)
	if Session.IsHost then
		return true;
	end

	local ctnode = CombatManager.getCTFromToken(token);
	if not ctnode then
		Debug.console("WARNING: failed to get CT node from token", token);
		return false;
	end
	local rActor = ActorManager.resolveActor(ctnode);
	if not rActor then
		Debug.console("WARNING: failed to resolve the actor from a combat tracker node", ctnode)
		return false;
	end
	return DB.isOwner(rActor.sCreatureNode)
end

----------------------------
-- MATH
----------------------------

function calculateSize()
	local columns = math.min(#aTokens, MAX_PER_ROW);
	local rows = math.ceil(#aTokens / MAX_PER_ROW);

	width = MARGINS + (columns * CONTROL_SIZE + ((columns - 1) * PADDING));
	height = MARGINS + (CONTROL_SIZE * rows) + ((rows - 1) * PADDING);

	return width, height;
end

function calculatePosition()
	local x, y = Input.getMousePosition();

	-- Shift y coord so that the box appears above the clicked position
	y = y - height;

	return x, y;
end

-----------------------------------
-- ACTIONS
-----------------------------------
function onTokenSelected(token, ctnode, bTop)
	local image = ImageManager.getImageControl(token);
	if not image then
		return true;
	end

	if self.getModifierKey("control") then
		if ctnode then
			self.targetToken(image, ctnode);
			self.bringTokenToTop(token);
		else
			Debug.console("Natural Selection: WARNING. Tried to target a token that doesn't exist on the combat tracker.")
		end
	else
		if bTop then
			self.selectToken(image, token, ctnode);
			self.bringTokenToTop(token);
		else
			self.pushTokenToBottom(token)
		end
	end

	self.close();

	return true;
end

function onDroppedOnToken(token, dragdata)
	self.bringTokenToTop(token)
	if TokenManager.onDrop(token, dragdata) then
		self.close();
	end
end

function targetToken(image, ctnode)
	for _, selected in ipairs(image.getSelectedTokens()) do
		local nodeSource = CombatManager.getCTFromToken(selected);
		if nodeSource then
			TargetingManager.notifyToggleTarget(nodeSource, ctnode)
		end
	end
end

function selectToken(image, token, ctnode)
	-- We only want to select a token if the owner is the one clicking it
	-- otherwise we leave the selection alone.
	-- If the ctnode is nil, then let anyone select the token, it's not a CT token.
	if self.isOwner(token) or ctnode == nil then
		local tokenId = token.getId();

		if not self.getModifierKey("shift") then
			image.clearSelectedTokens();
		end

		-- Toggle selection
		local bIsTokenSelected = image.isTokenSelected(tokenId);
		image.selectToken(tokenId, not bIsTokenSelected);
	end
end

function deselectToken(image, token)
	if image and token then
		image.selectToken(token.getId(), false);
	end
end

function bringTokenToTop(token)
	-- Hacky hack to get the token to the top of the stack.
	local x, y = token.getPosition();
	token.setPosition(x + 1, y + 1);
	token.setPosition(x, y);
end

function pushTokenToBottom(token)
	for _, tokendata in ipairs(aTokens) do
		-- We want to move every token except for the selected one.
		if tokendata.data.getId() ~= token.getId() then
			self.bringTokenToTop(tokendata.data);
		end
	end
end