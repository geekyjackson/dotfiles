local M = {}

local function split_lines(s)
	local lines = {}

	s = s or ""
	s = s:gsub("\r\n", "\n"):gsub("\r", "\n")

	for line in (s .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = line
	end

	return lines
end

local function slice_lines(lines, skip, height)
	skip = math.max(0, skip or 0)
	height = math.max(1, height or 1)

	local out = {}
	local last = math.min(#lines, skip + height)

	for i = skip + 1, last do
		out[#out + 1] = lines[i]
	end

	return table.concat(out, "\n")
end

function M:peek(job)
	local path = tostring(job.file.path)

	local output, err = Command("ffprobe")
		:arg({
			"-hide_banner",
			"-v", "error",
			"-show_format",
			"-show_streams",
			"-print_format", "json",
			"--",
			path,
		})
		:output()

	local text

	if not output then
		text = string.format("Failed to start `ffprobe`:\n\n%s", err)
	elseif output.status.success then
		text = output.stdout
	else
		text = string.format(
			"`ffprobe` exited with code %s:\n\n%s",
			output.status.code or "?",
			output.stderr ~= "" and output.stderr or output.stdout
		)
	end

	if text == "" then
		text = "ffprobe produced no output."
	end

	local header = string.format("ffprobe: %s\n%s\n", path, string.rep("─", 72))
	local lines = split_lines(header .. text)

	ya.preview_widget(
		job,
		ui.Text(slice_lines(lines, job.skip, job.area.h))
			:area(job.area)
			:wrap(ui.Wrap.NO)
	)
end

function M:seek(job)
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then
		return
	end

	local step = math.floor(job.units * job.area.h / 2)
	if step == 0 then
		step = ya.clamp(-1, job.units, 1)
	end

	ya.emit("peek", {
		math.max(0, cx.active.preview.skip + step),
		only_if = job.file.url,
	})
end

return M
