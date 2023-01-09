local ctnode;
local token;

function setData(tokendata, bTargeting)
	ctnode = tokendata.ctnode;
	token = tokendata.data
end

-- We need to allow everyone to select all tokens so they can bring them to the top to target
function onClickDown()
	return true;
end

function onClickRelease()
	self.onTokenSelected();
end

function onDrop(x, y, dragdata)
	window.onDroppedOnToken(token, dragdata);
end

function onTokenSelected()
	if window.onTokenSelected then
		window.onTokenSelected(token, ctnode);
	end
end