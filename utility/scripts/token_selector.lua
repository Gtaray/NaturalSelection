local CONTROL_SIZE = 50;
local PADDING = 4;
local MAX_PER_ROW = 3;
local MARGINS = 16;

local aTokens = {};
local height, width;

local bTargetingMode = false;

local fTokenSelectedCallback = nil;

function onInit()
	self.onSizeChanged = onSizeChanged;
end

function setTokens(tokens)
	aTokens = tokens;
end

function setTargetingMode(bMode)
	bTargetingMode = bMode;
end

function setTokenSelectedCallback(fCallback)
	fTokenSelectedCallback = fCallback;
end

function onTokenSelected(token)
	if fTokenSelectedCallback then
		fTokenSelectedCallback(token);
	end
end

function initialize()	
	self.calculateSize();
	setSize(width, height);

	local x = MARGINS / 2;
	
	for index, token in ipairs(aTokens or {}) do
		local col = (index - 1) % MAX_PER_ROW; -- -1 is to get the index back to being based on 0, not 1
		local row = math.floor((index - 1) / MAX_PER_ROW);

		local control = createControl("token_selector_token", "token_" .. index);
		control.setAnchor("left", "", "left", "absolute", (MARGINS / 2) + (col * CONTROL_SIZE) + ((col) * PADDING));
		control.setAnchor("top", "", "top", "absolute", (MARGINS / 2) + (row * CONTROL_SIZE) + ((row) * PADDING));
		control.setAnchoredWidth(CONTROL_SIZE);
		control.setAnchoredHeight(CONTROL_SIZE);
		control.setPrototype(token.data.getPrototype());

		-- Set widgets
		-- local aWidgets = TokenManager.getWidgetList(token.data)
		-- for _, vWidget in pairs(aWidgets) do
		-- 	if type(vWidget) == "bitmapwidget" then
		-- 		Debug.chat(vWidget)
		-- 		widget = token.data.addBitmapWidget(vWidget.getBitmap());
		-- 		widget.setName("foo");
		-- 		widget.setSize(vWidget.getSize())
		-- 		widget.setVisible(true);
		-- 		Debug.chat(widget);
		-- 	elseif type(vWidget) == "textwidget" then
		-- 	end
		-- end

		control.setData(token, bTargetingMode);
		token.control = control;
	end

	local x, y = calculatePosition();
	setPosition(x, y, false);
end

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