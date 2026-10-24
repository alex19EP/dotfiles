-- orca-ducking.lua
--
-- NVDA-style audio ducking for Orca: lower every other app's playback while
-- the screen reader is talking.
--
-- This script is only the actuator. The decision of *when* to duck lives in
-- the Orca extension (~/.local/share/orca/extensions/audio_ducking.py), which
-- sees speech-dispatcher's BEGIN/END events for each utterance and publishes
-- the target level, optionally followed by a fade time in ms, to a metadata
-- object this script owns:
--
--   pw-metadata -n orca-ducking 0 duck-level "0.3 150"  -- fade others to 30 % in 150 ms
--   pw-metadata -n orca-ducking 0 duck-level 1          -- restore, default fade
--
-- The level is applied as the stream's master `volume` Prop -- the same knob
-- WirePlumber's own role-based ducking uses. pipewire-pulse and GNOME only
-- show/persist `channelVolumes`, so the user's per-app volume is never touched
-- and state-stream never saves a ducked level.
--
-- Fades are stepped from here rather than with audioconvert's own
-- volumeRamp* props: a native ramp can't be retargeted mid-way (later volume
-- changes are overwritten by the rest of the ramp and new ramps are refused),
-- and it only advances while the stream processes audio, so a paused stream
-- would sit on a stale ramp. Speech constantly interrupts fades, so we need
-- them retargetable. Steps are linear in dB, which sounds even to the ear.
--
-- Not ducked: speech-dispatcher output modules (sd_*), Orca's own sounds, and
-- any loopback/filter stream (node.link-group) -- e.g. the dongle->analog
-- mirror carries speech too, and the apps feeding it are ducked individually.

log = Log.open_topic ("s-orca-ducking")

METADATA_NAME = "orca-ducking"
LEVEL_KEY     = "duck-level"

DEFAULT_FADE_MS = 300
STEP_MS         = 10      -- ~1 graph quantum; finer steps wouldn't be heard
FLOOR           = 0.001   -- -60 dB: stand-in for 0 when interpolating in dB

current    = 1.0   -- volume applied to non-speech streams right now
target     = 1.0   -- volume the current fade is heading to
fade       = nil   -- { from, to, start_us, duration_us } while fading
step_src   = nil
metadata   = nil   -- kept global so neither object is garbage-collected
streams_om = nil

local function is_excluded (node)
  local p = node.properties
  if p ["node.link-group"] ~= nil then
    return true
  end
  local binary = p ["application.process.binary"] or ""
  if binary:match ("^sd_") or binary == "speech-dispatcher" then
    return true
  end
  local app = (p ["application.name"] or ""):lower ()
  return app:match ("^speech%-dispatcher") ~= nil or app == "orca"
end

local function set_volume (node, volume)
  node:set_param ("Props", Pod.Object {
    "Spa:Pod:Object:Param:Props", "Props",
    volume = volume,
  })
end

local function apply_all ()
  for node in streams_om:iterate () do
    if not is_excluded (node) then
      set_volume (node, current)
    end
  end
end

-- Volume `t` (0..1) of the way from `a` to `b`, interpolated in dB.
local function lerp_db (a, b, t)
  if t >= 1.0 then
    return b
  end
  local la = math.log (math.max (a, FLOOR))
  local lb = math.log (math.max (b, FLOOR))
  return math.exp (la + (lb - la) * t)
end

local function stop_fade ()
  if step_src then
    step_src:destroy ()
    step_src = nil
  end
  fade = nil
end

local function fade_step ()
  step_src = nil
  if fade == nil then
    return
  end
  local t = (GLib.get_monotonic_time () - fade.start_us) / fade.duration_us
  current = lerp_db (fade.from, fade.to, t)
  apply_all ()
  if t >= 1.0 then
    fade = nil
  else
    step_src = Core.timeout_add (STEP_MS, fade_step)
  end
end

local function fade_to (to, duration_ms)
  stop_fade ()
  target = to
  if duration_ms <= 0 or to == current then
    current = to
    apply_all ()
    return
  end
  -- Starting from `current` (not the old target) means a fade interrupted
  -- half-way -- speech resuming while audio comes back up -- turns around
  -- smoothly from wherever it got to.
  fade = {
    from = current,
    to = to,
    start_us = GLib.get_monotonic_time (),
    duration_us = duration_ms * 1000,
  }
  fade_step ()
end

local function on_metadata_changed (m, subject, key, type, value)
  -- key == nil means the whole metadata was cleared
  if key ~= nil and key ~= LEVEL_KEY then
    return
  end
  local level_str, fade_str = (value or ""):match ("^%s*(%S*)%s*(%S*)")
  local new_level = math.max (0.0, math.min (1.0, tonumber (level_str) or 1.0))
  local fade_ms = math.max (0, math.min (5000, tonumber (fade_str) or DEFAULT_FADE_MS))
  if new_level == target then
    return
  end
  log:info (string.format ("duck level %.2f -> %.2f over %d ms", current, new_level, fade_ms))
  fade_to (new_level, fade_ms)
end

local function setup ()
  streams_om = ObjectManager {
    Interest {
      type = "node",
      Constraint { "media.class", "matches", "Stream/Output/Audio", type = "pw-global" },
    }
  }

  -- A stream that starts while ducked joins at the current (possibly
  -- mid-fade) level; later fade steps then carry it along with the rest.
  streams_om:connect ("object-added", function (om, node)
    if current < 1.0 and not is_excluded (node) then
      set_volume (node, current)
    end
  end)

  streams_om:activate ()

  metadata = ImplMetadata (METADATA_NAME)
  metadata:activate (Features.ALL, function (m, e)
    if e then
      log:warning ("failed to activate " .. METADATA_NAME .. " metadata: " .. tostring (e))
    else
      m:connect ("changed", on_metadata_changed)
    end
  end)
end

-- Same defensive pattern as mirror-dongle-to-analog.lua: this component is
-- `required`, so a setup error must not take WirePlumber (and Orca) down.
local ok, err = pcall (setup)
if not ok then
  log:warning ("orca ducking setup failed; audio unaffected, ducking disabled: " .. tostring (err))
end
