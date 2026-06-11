-- mirror-dongle-to-analog.lua
--
-- Mirror the Audeze Maxwell USB dongle's output to the onboard front-panel
-- analog headphone jack, so both sets of headphones play the same audio
-- (including Orca / speech-dispatcher output, which routes to the dongle).
--
-- SAFETY (this is the whole reason the script exists instead of a static
-- loopback): the analog sink only exists while something is plugged into the
-- front-panel jack -- when the jack is empty WirePlumber switches the card
-- profile to 'off' and the sink disappears. A loopback that captures the
-- dongle's monitor and is left without its analog target would have its
-- playback fall back to the default sink -- the dongle itself -- creating a
-- feedback loop (the buzz that broke login audio). So we:
--   * create the loopback ONLY while BOTH the dongle and analog sinks exist;
--   * destroy it the instant either disappears;
--   * set node.dont-reconnect on both streams so, even in the teardown race,
--     the linker refuses to move them to any other node ("dont-reconnect,
--     not moving" in linking/prepare-link.lua).

log = Log.open_topic ("s-dongle-mirror")

-- Stable node names of the two endpoints on alex-pc.
DONGLE = "alsa_output.usb-Audeze_LLC_Audeze_Maxwell_Dongle_0000000000000000-01.analog-stereo"
ANALOG = "alsa_output.pci-0000_7c_00.6.analog-stereo"

mirror_module  = nil    -- the live LocalModule, or nil when not mirroring
dongle_present = false
analog_present = false

function create_mirror ()
  if mirror_module ~= nil then
    return
  end

  -- Capture side: a Stream/Input that taps the DONGLE's monitor.
  local capture_props = {
    ["node.name"]           = "capture.dongle-mirror",
    ["node.description"]    = "Dongle mirror (tap dongle monitor)",
    ["media.class"]         = "Stream/Input/Audio",
    ["target.object"]       = DONGLE,
    ["stream.capture.sink"] = true,   -- capture the sink's monitor, not a source
    ["node.dont-reconnect"] = true,   -- never grab a different source
  }

  -- Playback side: a Stream/Output pinned to the ANALOG jack.
  local playback_props = {
    ["node.name"]           = "playback.dongle-mirror",
    ["node.description"]    = "Dongle mirror (to analog jack)",
    ["media.class"]         = "Stream/Output/Audio",
    ["target.object"]       = ANALOG,
    ["node.dont-reconnect"] = true,   -- never fall back to another sink (the dongle!)
    ["node.latency"]        = "128/48000",  -- ~2.7 ms quantum; lower = less echo, raise if it crackles
  }

  local args = Json.Object {
    ["capture.props"]  = Json.Object (capture_props),
    ["playback.props"] = Json.Object (playback_props),
  }

  log:info ("dongle + analog both present -> creating mirror loopback")
  mirror_module = LocalModule ("libpipewire-module-loopback", args:get_data (), {})
end

function destroy_mirror ()
  if mirror_module == nil then
    return
  end
  log:info ("dongle or analog gone -> destroying mirror loopback")
  mirror_module = nil   -- dropping the reference unloads the module
end

function reevaluate ()
  if dongle_present and analog_present then
    create_mirror ()
  else
    destroy_mirror ()
  end
end

-- Watch all audio sinks; track presence of our two endpoints by node.name.
-- ObjectManager emits "object-added" for sinks that already exist when it is
-- activated, so this also covers the headphones-already-plugged-at-login case.
sinks_om = nil   -- kept global so the manager is not garbage-collected

local function setup ()
  sinks_om = ObjectManager {
    Interest {
      type = "node",
      Constraint { "media.class", "matches", "Audio/Sink", type = "pw-global" },
    }
  }

  sinks_om:connect ("object-added", function (om, node)
    local name = node.properties ["node.name"]
    if name == DONGLE then
      dongle_present = true
      reevaluate ()
    elseif name == ANALOG then
      analog_present = true
      reevaluate ()
    end
  end)

  sinks_om:connect ("object-removed", function (om, node)
    local name = node.properties ["node.name"]
    if name == DONGLE then
      dongle_present = false
      reevaluate ()
    elseif name == ANALOG then
      analog_present = false
      reevaluate ()
    end
  end)

  sinks_om:activate ()
end

-- Defensive: this component is `required` in the profile, so a hard error here
-- would stop WirePlumber (and Orca with it). Contain any setup failure -- the
-- component still loads, WirePlumber starts, only the mirror is disabled.
local ok, err = pcall (setup)
if not ok then
  log:warning ("dongle mirror setup failed; audio unaffected, mirror disabled: " .. tostring (err))
end
