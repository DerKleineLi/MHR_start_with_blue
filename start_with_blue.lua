log.info("[start_with_blue.lua] loaded")

-- ##########################################
-- load modules
-- ##########################################
local quest_status = require("start_with_blue.quest_status");

quest_status.init_module();

-- ##########################################
-- constants
-- ##########################################
local weapon_names = {
    "Great Sword",
    "Slash Axe",
    "Long Sword",
    "Light Bow Gun",
    "Heavy Bow Gun",
    "Hammer",
    "Gun Lance",
    "Lance",
    "Short Sword",
    "Dual Blades",
    "Horn",
    "Charge Axe",
    "Insect Glaive",
    "Bow",
}

-- ##########################################
-- external API
-- ##########################################
function IsModuleAvailable(name)
    if package.loaded[name] then
        return true
    else
        for _, searcher in ipairs(package.searchers or package.loaders) do
        local loader = searcher(name)
        if type(loader) == 'function' then
            package.preload[name] = loader
            return true
        end
        end
        return false
    end
end

local apiPackageName = "easy_style_switch.api";
local ESS_api = nil;

if IsModuleAvailable(apiPackageName) then
    ESS_api = require(apiPackageName);
end

-- ##########################################
-- constants
-- ##########################################
local weapon_names = {
    "Great Sword",
    "Slash Axe",
    "Long Sword",
    "Light Bow Gun",
    "Heavy Bow Gun",
    "Hammer",
    "Gun Lance",
    "Lance",
    "Short Sword",
    "Dual Blades",
    "Horn",
    "Charge Axe",
    "Insect Glaive",
    "Bow",
}

-- ##########################################
>>>>>>> Stashed changes
-- script config
-- ##########################################
local cfg = json.load_file("start_with_blue_settings.json")

cfg = cfg or {}
cfg.enabled = cfg.enabled or false
cfg.weapon = cfg.weapon or {}
for i=1,14 do
    cfg.weapon[i] = cfg.weapon[i] or false
end

re.on_config_save(
    function()
        json.dump_file("start_with_blue_settings.json", cfg)
    end
)

-- ##########################################
-- global variables
-- ##########################################
local buff_id = nil; -- {0, 1} the current gui icon id, related to buff, 0 for red scroll, 1 for blue scroll.
local new_quest_initialized = false; -- indicates whether the id is set to 0 when entering a new quest or training area.

-- ##########################################
-- HUD update
-- ##########################################
local function update_hud()
    local gui_manager = sdk.get_managed_singleton("snow.gui.GuiManager");
    local guiHud_weaponTechniqueMySet = gui_manager:call("get_refGuiHud_WeaponTechniqueMySet");
    if not guiHud_weaponTechniqueMySet then return end
    local pnl_scrollicon = guiHud_weaponTechniqueMySet:get_field("pnl_scrollicon");

    if buff_id == 0 then
        pnl_scrollicon:call("set_PlayState", "DEFAULT_RED");
    elseif buff_id == 1 then
        pnl_scrollicon:call("set_PlayState", "DEFAULT_BLUE");
    end

    guiHud_weaponTechniqueMySet:write_dword(0x118, buff_id); -- guiHud_weaponTechniqueMySet:get_field("currentEquippedMySetIndex"):set_field("_Value", set_id);
end

-- ##########################################
-- switch function
-- ##########################################
local function switch_Myset(set_id)
    local player_manager = sdk.get_managed_singleton("snow.player.PlayerManager");
    local master_player = player_manager:call("findMasterPlayer");
    if not master_player then return false end
    local player_replace_atk_myset_holder = master_player:get_field("_ReplaceAtkMysetHolder");
    local weapon_type = master_player:get_field("_playerWeaponType")
    if not cfg.weapon[weapon_type+1] then return true end

    -- switch Myset
    player_replace_atk_myset_holder:call("setSelectedMysetIndex", set_id);
    master_player:set_field("_replaceAttackTypeA", player_replace_atk_myset_holder:call("getReplaceAtkTypeFromMyset",0))
    master_player:set_field("_replaceAttackTypeB", player_replace_atk_myset_holder:call("getReplaceAtkTypeFromMyset",1))
    master_player:set_field("_replaceAttackTypeC", player_replace_atk_myset_holder:call("getReplaceAtkTypeFromMyset",2))
    master_player:set_field("_replaceAttackTypeD", player_replace_atk_myset_holder:call("getReplaceAtkTypeFromMyset",3))
    master_player:set_field("_replaceAttackTypeE", player_replace_atk_myset_holder:call("getReplaceAtkTypeFromMyset",4))
    master_player:set_field("_replaceAttackTypeF", player_replace_atk_myset_holder:call("getReplaceAtkTypeFromMyset",5))
    buff_id = set_id;

    update_hud();
    if ESS_api then
        ESS_api.update();
    end
    return true;
end


-- ##########################################
-- on frame
-- ##########################################

re.on_frame(function()
    if not cfg.enabled then return end

    -- initialize quest
    if quest_status.in_active_area() then
        if not new_quest_initialized then
            new_quest_initialized = switch_Myset(1)
        end
    else
        new_quest_initialized = false;
    end
end)

-- ##########################################
-- reframework UI
-- ##########################################
re.on_draw_ui(
    function() 
        if not imgui.tree_node("Start with blue") then return end

        local changed, value = imgui.checkbox("Enabled", cfg.enabled)
        if changed then cfg.enabled = value end

        if imgui.tree_node("Weapon settings") then
            for i=1,14 do
                local changed, value = imgui.checkbox(weapon_names[i], cfg.weapon[i])
                if changed then cfg.weapon[i] = value end
            end
            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
)