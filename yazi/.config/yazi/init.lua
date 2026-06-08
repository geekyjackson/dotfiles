require("smart-enter"):setup {
	open_multi = true,
}

require("folder-rules"):setup()

function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)

	if time == 0 then
		time = ""
	elseif os.date("%Y-%m-%d", time) == os.date("%Y-%m-%d") then
		time = os.date("%H:%M", time)
	else
		time = os.date("%Y-%m-%d", time)
	end

	local size = self._file:size()
    return string.format("%s %10s", size and ya.readable_size(size) or "-", time)
end

Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)


function Tab:layout()
	local w = self._area.w

	local parent 
	local current
	local preview

	if w < 92 then
		parent = 0
        current = 1
		preview = 0
	elseif w < 132 then
		parent = 0
        current = 2
        preview = 1
    else
        parent = 1
        current = 2
        preview = 1
    end

	local all = parent + current + preview

	self._chunks = ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Ratio(parent, all),
			ui.Constraint.Ratio(current, all),
			ui.Constraint.Ratio(preview, all),
		})
		:split(self._area)
end
