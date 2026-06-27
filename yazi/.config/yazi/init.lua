require("smart-enter"):setup { open_multi = true }

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

Status:children_add(function (self)
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
            ui.Constraint.Ratio(preview, all)
        })
        :split(self._area)
end

require("gvfs"):setup({
    -- (Optional) Allowed keys to select device.
    which_keys = "1234567890qwertyuiopasdfghjklzxcvbnm-=[]\\;',./!@#$%^&*()_+{}|:\"<>?",

    -- (Optional) Table of blacklisted devices. These devices will be ignored in any actions
  -- List of device properties to match, or a string to match the device name:
  -- https://github.com/boydaihungst/gvfs.yazi/blob/master/main.lua#L144
    blacklist_devices = { { name = "Wireless Device", scheme = "mtp" }, { scheme = "file" }, "Device Name" },

    -- (Optional) Save file.
  -- Default: ~/.config/yazi/gvfs.private
    save_path = os.getenv("HOME") .. "/.config/yazi/gvfs.private",

    -- (Optional) Save file for automount devices. Use with `automount-when-cd` action.
  -- Default: ~/.config/yazi/gvfs_automounts.private
    save_path_automounts = os.getenv("HOME") .. "/.config/yazi/gvfs_automounts.private",

    -- (Optional) Input box position.
  -- Default: { "top-center", y = 3, w = 60 },
  -- Position, which is a table:
  -- 	`1`: Origin position, available values: "top-left", "top-center", "top-right",
  -- 	     "bottom-left", "bottom-center", "bottom-right", "center", and "hovered".
  --         "hovered" is the position of hovered file/folder
  -- 	`x`: X offset from the origin position.
  -- 	`y`: Y offset from the origin position.
  -- 	`w`: Width of the input.
  -- 	`h`: Height of the input.
    input_position = { "center", y = 0, w = 60 },

    -- (Optional) Select where to save passwords.
  -- Default: nil
  -- Available options: "keyring", "pass", or nil
    password_vault = "keyring",

    -- (Optional) Only need if you set password_vault = "pass"
  -- Read the guide at SECURE_SAVED_PASSWORD.md to get your key_grip
    key_grip = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",

    -- (Optional) Auto-save password after mount.
  -- Default: false
    save_password_autoconfirm = true
    -- (Optional) mountpoint of gvfs. Default: /run/user/USER_ID/gvfs
  -- On some system it could be ~/.gvfs
  -- You can't decide this path, it will be created automatically. Only changed if you know where gvfs mountpoint is.
  -- Use command `ps aux | grep gvfs` to search for gvfs process and get the mountpoint path.
  -- root_mountpoint = (os.getenv("XDG_RUNTIME_DIR") or ("/run/user/" .. ya.uid())) .. "/gvfs"
})
