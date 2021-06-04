-- Export adventurer data into an JSON file for use in importadv script.
-- Script version: v0.3.0
-- For DF v0.47.05
--[====[
exportadv
=============
Export adventurer data into an JSON file for use in importadv script.
Currently, this script exports adventurer skills, attributes, appearance, and personality.

This script will create a file in the format:
    exported_adventurers/{first_name}-{save_folder}-YYYYY-MM-DD-adventurer.json

Simply enter adventure mode with your character and run this script!
Usage::
    exportadv
]====]

local json = require "json"

------------------
-- Unit parsing --
------------------
unit_export_data = {
    name = "default",
    race = -1,
    sex = -1,
    profession = -1,
    profession2 = -1,
    appearance = {
        size_modifier = -1,
        body_modifiers = {},
        bp_modifiers = {},
        tissue_style = {},
        tissue_style_civ_id = {},
        tissue_style_id = {},
        tissue_style_type = {},
        tissue_length = {},
        colors = {},
        genes = { appearance = {}, colors = {} }
    },
    body_metadata = {},
    personality = { values = {}, traits = {}, dreams = {} },
    skills = {},
    attributes = {}
}

function get_unit_attributes(unit)
    for attribute_name, attribute in pairs(unit.body.physical_attrs) do
        unit_export_data.attributes[attribute_name] = {
            value = attribute.value,
            max_value = attribute.max_value
        }
    end

    for attribute_name, attribute in pairs(unit.status.current_soul.mental_attrs) do
        unit_export_data.attributes[attribute_name] = {
            value = attribute.value,
            max_value = attribute.max_value
        }
    end
end

function skill_id_to_name(target_id)
    for id, name in ipairs(df.job_skill) do
        if id == target_id then
            return name
        end
    end
    return "UNKNOWN"
end

function get_unit_skills(unit)
    for index, skill in ipairs(unit.status.current_soul.skills) do
        unit_export_data.skills[tostring(skill.id)] = {
            name = skill_id_to_name(skill.id),
            rating = skill.rating,
            experience = skill.experience
        }
    end
end

function get_unit_body_metadata(unit)
    unit_export_data.body_metadata.weapon_bp = unit.body.weapon_bp
    unit_export_data.body_metadata.blood_max = unit.body.blood_max
    unit_export_data.body_metadata.size_info = {
        size_cur = unit.body.size_info.size_cur,
        size_base = unit.body.size_info.size_base,
        area_cur = unit.body.size_info.area_cur,
        area_base = unit.body.size_info.area_base,
        length_cur = unit.body.size_info.length_cur,
        length_base = unit.body.size_info.length_base
    }
end

function add_vector_to_table(vector, target_table)
    for index, value in ipairs(vector) do
        target_table[index] = value
    end
end

function get_unit_appearance(unit)
    unit_export_data.appearance.size_modifier = unit.appearance.size_modifier
    add_vector_to_table(unit.appearance.body_modifiers, unit_export_data.appearance.body_modifiers)
    add_vector_to_table(unit.appearance.bp_modifiers, unit_export_data.appearance.bp_modifiers)
    add_vector_to_table(unit.appearance.tissue_style, unit_export_data.appearance.tissue_style)
    add_vector_to_table(unit.appearance.tissue_style_civ_id, unit_export_data.appearance.tissue_style_civ_id)
    add_vector_to_table(unit.appearance.tissue_style_id, unit_export_data.appearance.tissue_style_id)
    add_vector_to_table(unit.appearance.tissue_style_type, unit_export_data.appearance.tissue_style_type)
    add_vector_to_table(unit.appearance.tissue_length, unit_export_data.appearance.tissue_length)
    add_vector_to_table(unit.appearance.colors, unit_export_data.appearance.colors)
    add_vector_to_table(unit.appearance.genes.appearance, unit_export_data.appearance.genes.appearance)
    add_vector_to_table(unit.appearance.genes.colors, unit_export_data.appearance.genes.colors)
end

function get_field_names(t)
    local names = {}
    local i,v=next(t,nil)
    while i do
        tinsert(names,i)
        i,v=next(t,i)
    end
    return names
end

function extract_unseen_beliefs(unit, beliefs)
    local personality = unit.status.current_soul.personality
    for id, value_name in ipairs(df.value_type) do
        if id == df.value_type.NONE then
            goto continue
        end
        if not unit_export_data.personality.values[id] then
            unit_export_data.personality.values[id] = { name = value_name, strength = beliefs[id] }
        end
        ::continue::
    end
end

function get_unit_personality(unit)
    local personality = unit.status.current_soul.personality

    -- Personal beliefs
    for i, value in ipairs(personality.values) do
        unit_export_data.personality.values[value.type] = { name = df.value_type[value.type], strength = value.strength }
    end

    -- Cultural beliefs
    if personality.cultural_identity ~= -1 then
        extract_unseen_beliefs(unit, df.cultural_identity.find(personality.cultural_identity).values)
    elseif personality.civ_id ~= -1 then
        extract_unseen_beliefs(unit, df.historical_entity.find(personality.civ_id).resources.values)
    end

    -- Traits
    for name, strength in pairs(personality.traits) do
        unit_export_data.personality.traits[name] = strength
    end

    -- Dreams
    for i, dream in ipairs(personality.dreams) do
        unit_export_data.personality.dreams[tostring(dream.type)] = { accomplished = dream.flags.accomplished }
    end
end

function get_unit_metadata(unit)
    unit_export_data.name = unit.name.first_name
    unit_export_data.race = unit.race
    unit_export_data.sex = unit.sex
    unit_export_data.profession = unit.profession
    unit_export_data.profession2 = unit.profession2
end

--------------------
-- Export process --
--------------------
function create_folder(folder_name)
    if dfhack.filesystem.isfile(folder_name) then
        qerror(folder_name .. " is a file, not a folder")
    end
    if dfhack.filesystem.exists(folder_name) then
        return true
    else
        return dfhack.filesystem.mkdir(folder_name)
    end
end

function get_world_date_str()
    local month = dfhack.world.ReadCurrentMonth() + 1 --days and months are 1-indexed
    local day = dfhack.world.ReadCurrentDay()
    local date_str = string.format("%05d-%02d-%02d", df.global.cur_year, month, day)
    return date_str
end

function export_to_json(export_data)
    local folder_name = "exported_adventurers"
    local file_name =
        export_data.name ..
        "-" .. df.global.world.cur_savegame.save_dir .. "-" .. get_world_date_str() .. "-adventurer.json"
    local full_file_path = folder_name .. "/" .. file_name
    create_folder(folder_name)

    print(string.format("\nWriting to %s ...", full_file_path))
    json.encode_file(export_data, full_file_path)
    print("Done!")
end

function export_adv()
    local target = df.global.world.units.active[0]
    if not target then
        qerror("No valid unit selected!")
    end
    get_unit_attributes(target)
    get_unit_skills(target)
    get_unit_appearance(target)
    get_unit_body_metadata(target)
    get_unit_personality(target)
    get_unit_metadata(target)
    export_to_json(unit_export_data)
end

export_adv()
