-- =========================================================================
-- USER CONFIGURATION - Customize these values for your setup
-- =========================================================================

-- The folder where you cloned this repository (HyprDots)
hyprdots_dir = os.getenv("HOME") .. "/.local/src/HyprDots"

-- Your active wallpaper path
wallpaper_path = os.getenv("HOME") .. "/Pictures/Wallpapers/eki.jpg"

-- The path to your Obsidian vault (where matugen.css snippet should be generated)
obsidian_vault = os.getenv("HOME") .. "/ObsidianVault"

-- The directory name of your Zen browser profile under ~/.config/zen/
-- Look inside ~/.config/zen/ to find your profile name (it usually ends with ".Default (release)")
zen_profile = "vzvuye4x.Default (release)"

-- Preferred default applications
mainMod = "SUPER"
terminal = "kitty"
filemanager = "dolphin"
code_editor = "code"
browser = "firefox"

-- =========================================================================
-- SYSTEM CONFIGURATION - Do not modify below this line
-- =========================================================================

-- Set the directory for screenshots
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/hyprshot/")

-- Set the current desktop environment to KDE to ensure compatibility with certain applications (like dolphin)
hl.env("XDG_CURRENT_DESKTOP", "KDE")

-- Helper to read file content
local function read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

-- Helper to write file content (creates directory if it doesn't exist)
local function write_file(path, content)
    local dir = path:match("(.+)/[^/]+$")
    if dir then
        os.execute("mkdir -p " .. dir)
    end
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

-- Function to dynamically generate configs based on user setup on startup
local function generate_user_configs()
    local home = os.getenv("HOME")
    
    local replacements = {
        ["{{HYPRDOTS_DIR}}"] = hyprdots_dir,
        ["{{WALLPAPER_PATH}}"] = wallpaper_path,
        ["{{OBSIDIAN_VAULT}}"] = obsidian_vault,
        ["{{ZEN_PROFILE}}"] = zen_profile,
    }

    local function substitute(template)
        if not template then return nil end
        local content = template
        for k, v in pairs(replacements) do
            local k_pattern = k:gsub("([^%w])", "%%%1")
            local v_replacement = v:gsub("%%", "%%%%")
            content = content:gsub(k_pattern, v_replacement)
        end
        return content
    end

    -- Update matugen config
    local matugen_template = read_file(hyprdots_dir .. "/matugen/config.toml.template")
    if matugen_template then
        local matugen_content = substitute(matugen_template)
        write_file(hyprdots_dir .. "/matugen/config.toml", matugen_content)
        write_file(home .. "/.config/matugen/config.toml", matugen_content)
    end

    -- Update hyprpaper.conf
    local hyprpaper_template = read_file(hyprdots_dir .. "/hypr/hyprpaper.conf.template")
    if hyprpaper_template then
        local hyprpaper_content = substitute(hyprpaper_template)
        write_file(hyprdots_dir .. "/hypr/hyprpaper.conf", hyprpaper_content)
        write_file(home .. "/.config/hypr/hyprpaper.conf", hyprpaper_content)
    end

    -- Update tide-island userconfig.json
    local island_template = read_file(hyprdots_dir .. "/tide-island/userconfig.json.template")
    if island_template then
        local island_content = substitute(island_template)
        write_file(hyprdots_dir .. "/tide-island/userconfig.json", island_content)
        write_file(home .. "/.config/tide-island/userconfig.json", island_content)
    end
end

-- Generate dynamic configurations
generate_user_configs()