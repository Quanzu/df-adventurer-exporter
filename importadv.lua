-- Import adventurer data from a JSON file generated by the exportadv script.
-- Script version: v0.1.0
-- For DF v0.47.05
--[====[

importadv
=============
Import adventurer data from a JSON file generated by the exportadv script.

Currently, this script only imports skills, attributes, and professions.
Future iterations will hopefully be able to import more data to more accurately
reconstruct an adventurer.

Simply enter adventure mode with your character and run this script!

Usage::

    importadv [FILEPATH]

]====]

local args = {...}
local json = require "json"
local utils = require "utils"

function set_attributes(attributes_to_replace, attributes_to_copy)
    for i, attribute in ipairs(attributes_to_copy) do
        for attribute_name, unit_attribute in pairs(attributes_to_replace) do
            if attribute_name == attribute.name then
                print(
                    string.format(
                        "Setting %s to value %d and max_value %d.",
                        attribute_name,
                        attribute.value,
                        attribute.max_value
                    )
                )
                unit_attribute.value = attribute.value
                unit_attribute.max_value = attribute.max_value
            end
        end
    end
end  

function set_body_attributes(unit, body_attributes)
    print("\n-------SETTING PHYSICAL ATTRIBUTES-------")
    set_attributes(unit.body.physical_attrs, body_attributes)
end

function set_mental_attributes(unit, mental_attributes)
    print("\n-------SETTING MENTAL ATTRIBUTES-------")
    set_attributes(unit.status.current_soul.mental_attrs, mental_attributes)
end

function find_skill_in_unit(unit, skill_id)
    for i, skill in ipairs(unit.status.current_soul.skills) do
        if skill.id == skill_id then
            return skill
        end
    end
    return nil
end

function set_skill_data(unit, skills)
    print("\n-------SETTING SKILLS-------")
    for i, skill in ipairs(skills) do
        local target_skill = find_skill_in_unit(unit, skill.id)
        print(string.format("Setting %s to rating %d and experience %d.", skill.name, skill.rating, skill.experience))
        if not target_skill then
            target_skill = df.unit_skill:new()
            target_skill.id = skill.id
            target_skill.rating = skill.rating
            target_skill.experience = skill.experience
            utils.insert_sorted(unit.status.current_soul.skills, target_skill, "id")
        else
            target_skill.rating = skill.rating
            target_skill.experience = skill.experience
        end
    end
end

function set_unit_data(target_unit, unit_data)
    target_unit.profession = unit_data.profession
    target_unit.profession2 = unit_data.profession2
    set_body_attributes(target_unit, unit_data.body_attributes)
    set_mental_attributes(target_unit, unit_data.mental_attributes)
    set_skill_data(target_unit, unit_data.skills)
end

function import_adv()
    if #args ~= 1 then
        qerror("importadv requires only one argument: the path to the exported JSON file.")
    end
    local target_unit = df.global.world.units.active[0]
    local unit_data = json.decode_file(args[1])

    print("\nImporting data from adventurer " .. unit_data.name .. " ...")
    set_unit_data(target_unit, unit_data)
    print("\nDone!")
end

import_adv()
