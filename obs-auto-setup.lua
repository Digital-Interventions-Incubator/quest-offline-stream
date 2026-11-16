-- Quest Stream auto-setup for OBS Studio (Windows, OBS 30+)
--
-- One-time install: Tools > Scripts > + > select this file (keep it loaded).
-- Then: start queststream.bat (scrcpy window live), and in this script's
-- dialog click "Apply Quest Stream Setup" once.
--
-- What it does (idempotent, safe to click again):
--   1. Creates the scene "Quest Stream".
--   2. Creates a Window Capture source named "Quest3Full" (matches the
--      scrcpy window by title).
--   3. Adds a "Crop One Eye" crop filter (removes the right eye and
--      centers to 16:9, computed from the live capture size).
--   4. Rotates the item -22 deg (Quest 3 downward camera angle) and
--      fits it to the canvas.
--   5. Switches OBS to the Quest Stream scene.
--
-- If the source shows black: open the source's Properties and re-pick the
-- "Quest3Full" window, then click the button again.

local SCENE_NAME = "Quest Stream"
local SOURCE_NAME = "Quest3Full"
local FILTER_NAME = "Crop One Eye"
local WINDOW_TITLE = "Quest3Full"
local ROTATION = -22

local ALIGN_TOP_LEFT = 5 -- OBS_ALIGN_LEFT(1) | OBS_ALIGN_TOP(4)
local ALIGN_CENTER = 0

local function log(msg)
    obs.script_log(obs.LOG_INFO, msg)
end

local function warn(msg)
    obs.script_log(obs.LOG_WARNING, msg)
end

local function get_canvas_size()
    local w, h = 1920, 1080
    local ovi = obs.obs_video_info()
    if obs.obs_get_video_info(ovi) and ovi.base_width > 0 then
        w = ovi.base_width
        h = ovi.base_height
    end
    return w, h
end

local function get_or_create_scene()
    local src = obs.obs_get_source_by_name(SCENE_NAME)
    if src then
        local scene = obs.obs_scene_from_source(src)
        obs.obs_source_release(src)
        return scene
    end
    local added = obs.obs_frontend_add_scene(SCENE_NAME)
    if not added then
        warn("Could not create scene " .. SCENE_NAME)
        return nil
    end
    local scene = obs.obs_scene_from_source(added)
    obs.obs_source_release(added)
    return scene
end

local function get_or_create_capture_source()
    local src = obs.obs_get_source_by_name(SOURCE_NAME)
    if src then
        return src
    end
    local settings = obs.obs_data_create()
    -- Window Capture stores "title:class:hwnd"; OBS 30+ can match on title
    -- alone when priority = 1 (window title).
    obs.obs_data_set_string(settings, "window", WINDOW_TITLE)
    obs.obs_data_set_int(settings, "priority", 1)
    src = obs.obs_source_create("window_capture", SOURCE_NAME, settings, nil)
    obs.obs_data_release(settings)
    return src
end

local function compute_crop(source)
    -- Defaults; replaced with exact values when the capture is live.
    local crop = { left = 0, top = 200, right = 800, bottom = 200 }
    local w = obs.obs_source_get_width(source)
    local h = obs.obs_source_get_height(source)
    if w > 0 and h > 0 then
        crop.right = math.floor(w / 2) -- drop the right eye
        local want_h = math.floor((w / 2) * 9 / 16) -- 16:9 of the remaining eye
        local v = math.floor((h - want_h) / 2)
        crop.top = v
        crop.bottom = v
        log(("Capture %dx%d -> crop right=%d top=%d bottom=%d")
            :format(w, h, crop.right, crop.top, crop.bottom))
    else
        warn("Capture not live yet: using default crop (800/200/200). Start the stream, then click the button again for the exact crop.")
    end
    return crop
end

local function setup_filter(source)
    local crop = compute_crop(source)
    local settings = obs.obs_data_create()
    obs.obs_data_set_bool(settings, "relative", false)
    obs.obs_data_set_int(settings, "left", crop.left)
    obs.obs_data_set_int(settings, "top", crop.top)
    obs.obs_data_set_int(settings, "right", crop.right)
    obs.obs_data_set_int(settings, "bottom", crop.bottom)

    local filter
    if obs.obs_source_get_filter_by_name then
        filter = obs.obs_source_get_filter_by_name(source, FILTER_NAME)
    end
    if filter then
        obs.obs_source_update(filter, settings)
        obs.obs_source_release(filter)
    else
        filter = obs.obs_source_create("crop_filter", FILTER_NAME, settings, nil)
        obs.obs_source_filter_add(source, filter)
        obs.obs_source_release(filter)
    end
    obs.obs_data_release(settings)
end

local function setup_transform(scene, source)
    local item = obs.obs_scene_find_source(scene, SOURCE_NAME)
    if not item then
        warn("Source not found in scene")
        return
    end
    local cw, ch = get_canvas_size()
    local info = obs.obs_transform_info()
    info.pos.x = 0
    info.pos.y = 0
    info.rot = ROTATION
    info.scale.x = 1
    info.scale.y = 1
    info.alignment = ALIGN_TOP_LEFT
    info.bounds_type = obs.OBS_BOUNDS_FIT
    info.bounds_alignment = ALIGN_CENTER
    info.bounds.x = cw
    info.bounds.y = ch
    obs.obs_sceneitem_set_info(item, info)
    obs.obs_sceneitem_release(item)
end

function apply_setup_clicked()
    local scene = get_or_create_scene()
    if not scene then
        return false
    end
    local source = get_or_create_capture_source()
    if not source then
        warn("Could not create the capture source")
        return false
    end

    -- Add to scene if not present yet.
    local scene_source = obs.obs_scene_get_source(scene)
    if not obs.obs_scene_find_source(scene, SOURCE_NAME) then
        obs.obs_scene_add(scene, source)
    end

    setup_filter(source)
    setup_transform(scene, source)
    obs.obs_frontend_set_current_scene(scene_source)

    obs.obs_source_release(source)
    obs.obs_source_release(scene_source)
    log("Quest Stream setup applied.")
    return false
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_button(props, "apply_setup", "Apply Quest Stream Setup", apply_setup_clicked)
    return props
end

function script_description()
    return "Quest Stream auto-setup.\n"
        .. "1. Keep this script loaded (Tools > Scripts).\n"
        .. "2. Start queststream.bat so the scrcpy window is live.\n"
        .. "3. Click 'Apply Quest Stream Setup' once.\n"
        .. "4. Right-click the preview > Fullscreen Projector > your TV.\n\n"
        .. "If the source is black, open its Properties and re-pick the "
        .. "Quest3Full window, then click the button again."
end

function script_load(settings)
end
