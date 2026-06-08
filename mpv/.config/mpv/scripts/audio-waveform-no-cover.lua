-- ~/.config/mpv/scripts/audio-waveform-no-cover.lua

local waveform_graph =
    "[aid1]asplit[ao][a1];" ..
    "[a1]showspectrum=s=1920x1080:mode=combined:color=intensity,format=yuv420p[vo]"

local function inspect_tracks()
    local tracks = mp.get_property_native("track-list", {})

    local has_audio = false
    local has_cover_art = false
    local has_real_video = false

    for _, track in ipairs(tracks) do
        if track.type == "audio" then
            has_audio = true
        elseif track.type == "video" then
            if track.albumart then
                has_cover_art = true
            else
                has_real_video = true
            end
        end
    end

    return has_audio, has_cover_art, has_real_video
end

mp.add_hook("on_preloaded", 50, function()
    local has_audio, has_cover_art, has_real_video = inspect_tracks()

    -- Only synthesize waveform for audio-only files with no cover art.
    -- This includes .webm/.opus audio files.
    if has_audio and not has_cover_art and not has_real_video then
        mp.set_property("file-local-options/audio-display", "no")
        mp.set_property("file-local-options/lavfi-complex", waveform_graph)
    end
end)
