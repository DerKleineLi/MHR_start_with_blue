
local quest_status = {};

quest_status.quest_manager = nil;
quest_status.village_area_manager = nil;
quest_status.index = 0;
quest_status.is_training_area = false;
quest_status.update_is_result_screen = false;

local quest_manager_type_definition = sdk.find_type_definition("snow.QuestManager");
local on_changed_game_status = quest_manager_type_definition:get_method("onChangedGameStatus");
local get_status_method = quest_manager_type_definition:get_method("getStatus");
local is_result_demo_play_start_method = quest_manager_type_definition:get_method("isResultDemoPlayStart");

local village_area_manager_type_def = sdk.find_type_definition("snow.VillageAreaManager");
local check_current_area_training_area_method = village_area_manager_type_def:get_method("checkCurrentArea_TrainingArea");

function quest_status.update(args)
	local new_quest_status = sdk.to_int64(args[3]);
	if new_quest_status ~= nil then
		quest_status.index = new_quest_status;
	end
end

function quest_status.init()
	if not quest_status.init_quest_manager() then
		return;
	end

	local new_quest_status = get_status_method:call(quest_status.quest_manager);
	if new_quest_status == nil then
		return;
	end

	quest_status.index = new_quest_status;
	quest_status.update_is_training_area();
	quest_status.update_is_result_screen();
end

function quest_status.update_is_training_area()
	if not quest_status.init_village_area_manager() then
		return;
	end

	local _is_training_area = check_current_area_training_area_method:call(quest_status.village_area_manager);
	if _is_training_area == nil then
		return;
	end

	quest_status.is_training_area = _is_training_area;
end

function quest_status.update_is_result_screen()
	if not quest_status.init_quest_manager() then
		return;
	end

	local is_result_demo_play_start = is_result_demo_play_start_method:call(quest_status.quest_manager);
	if is_result_demo_play_start == nil then
		return;
	end

	quest_status.is_result_screen = is_result_demo_play_start;
end

function quest_status.init_module()
	quest_status.init();
	quest_status.init_quest_manager();
    quest_status.init_village_area_manager();

	sdk.hook(on_changed_game_status, function(args)
		pcall(quest_status.update, args);
	end, function(retval) return retval; end);
end

function quest_status.init_quest_manager()
	if quest_status.quest_manager == nil then
		quest_status.quest_manager = sdk.get_managed_singleton("snow.QuestManager");
	    return quest_status.quest_manager;
    else
        return true
    end
end

function quest_status.init_village_area_manager()
	if quest_status.village_area_manager == nil then
	    quest_status.village_area_manager = sdk.get_managed_singleton("snow.VillageAreaManager");
	    return quest_status.village_area_manager;
    else
        return true
    end
end

function quest_status.in_active_area()

    if quest_status.index < 2 then
        quest_status.update_is_training_area();
        if quest_status.is_training_area then
            return true
        end
    end

    quest_status.update_is_result_screen();
    if quest_status.is_result_screen then
        return true
    end

    if quest_status.index == 2 then
        return true
    end

    return false
end

return quest_status;