-- Export adventurer data into an JSON file for use in importadv script.
-- Script version: v0.2.0
-- For DF v0.47.05
--[====[
exportadv
=============
Export adventurer data into an JSON file for use in importadv script.
Currently, this script only exports adventurer skills, attributes, and professions.
Future iterations will hopefully be able to export more data to more accurately
reconstruct an adventurer.
This script will create a file in the format:
    exported_adventurers/{first_name}-{save_folder}-YYYYY-MM-DD-adventurer.json
Simply enter adventure mode with your character and run this script!
Usage::
    exportadv
]====]

local json = require "json"

-- Attribute Class
local Attribute = {}
Attribute.__index = Attribute

function Attribute:new(name, value, max_value)
    this = {
        name = name or "default",
        value = value or 0,
        max_value = max_value or 0
    }
    setmetatable(this, Attribute)
    return this
end

function Attribute:toString()
    return string.format("name: %30s, value: %5d, max_value: %5d", self.name, self.value, self.max_value)
end

-- Skill Class
local Skill = {}
Skill.__index = Skill

function Skill:new(id, rating, experience)
    this = {
        id = id or 0,
        rating = rating or 0,
        experience = experience or 0,
        name = skill_id_to_name(id or 0)
    }
    setmetatable(this, Skill)
    return this
end

function Skill:toString()
    return string.format(
        "name: %30s, id: %4d, rating: %4d, experience: %d",
        self.name,
        self.id,
        self.rating,
        self.experience
    )
end

function skill_id_to_name(target_id)
    for id, name in ipairs(df.job_skill) do
        if id == target_id then
            return name
        end
    end
    return "UNKNOWN"
end

-- Unit parsing
unit_export_data = {
    name = "default",
    race = -1,
    sex = -1,
    profession = -1,
    profession2 = -1,
    appearance = {},
    body_metadata = {},
    personality = {},
    skills = {},
    body_attributes = {},
    mental_attributes = {}
}

function get_unit_attributes(unit)
    for attribute_name, attribute in pairs(unit.body.physical_attrs) do
        attr_data = Attribute:new(attribute_name, attribute.value, attribute.max_value)
        table.insert(unit_export_data.body_attributes, attr_data)
    end

    for attribute_name, attribute in pairs(unit.status.current_soul.mental_attrs) do
        attr_data = Attribute:new(attribute_name, attribute.value, attribute.max_value)
        table.insert(unit_export_data.mental_attributes, attr_data)
    end
end

function get_unit_skills(unit)
    for index, skill in ipairs(unit.status.current_soul.skills) do
        local skill_data = Skill:new(skill.id, skill.rating, skill.experience)
        table.insert(unit_export_data.skills, skill_data)
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

function get_unit_appearance(unit)
    unit_export_data.appearance.body_modifiers = {}
    for id, value in pairs(unit.appearance.body_modifiers) do
        modifier = {id = id, value = value}
        table.insert(unit_export_data.appearance.body_modifiers, modifier)
    end

    unit_export_data.appearance.bp_modifiers = {}
    for id, value in pairs(unit.appearance.bp_modifiers) do
        modifier = {id = id, value = value}
        table.insert(unit_export_data.appearance.bp_modifiers, modifier)
    end

    unit_export_data.appearance.size_modifier = unit.appearance.size_modifier

    unit_export_data.appearance.tissue_style = {}
    for id, value in pairs(unit.appearance.tissue_style) do
        ts = {id = id, value = value}
        table.insert(unit_export_data.appearance.tissue_style, ts)
    end

    unit_export_data.appearance.tissue_style_civ_id = {}
    for id, value in pairs(unit.appearance.tissue_style_civ_id) do
        ts = {id = id, value = value}
        table.insert(unit_export_data.appearance.tissue_style_civ_id, ts)
    end

    unit_export_data.appearance.tissue_style_id = {}
    for id, value in pairs(unit.appearance.tissue_style_id) do
        ts = {id = id, value = value}
        table.insert(unit_export_data.appearance.tissue_style_id, ts)
    end

    unit_export_data.appearance.tissue_style_type = {}
    for id, value in pairs(unit.appearance.tissue_style_type) do
        ts = {id = id, value = value}
        table.insert(unit_export_data.appearance.tissue_style_type, ts)
    end

    unit_export_data.appearance.tissue_length = {}
    for id, value in pairs(unit.appearance.tissue_length) do
        ts = {id = id, value = value}
        table.insert(unit_export_data.appearance.tissue_length, ts)
    end

    unit_export_data.appearance.colors = {}
    for id, value in pairs(unit.appearance.colors) do
        color = {id = id, value = value}
        table.insert(unit_export_data.appearance.colors, color)
    end

    unit_export_data.appearance.genes = {appearance = {}, colors = {}}
    for id, value in pairs(unit.appearance.genes.appearance) do
        gene = {id = id, value = value}
        table.insert(unit_export_data.appearance.genes.appearance, gene)
    end
    for id, value in pairs(unit.appearance.genes.colors) do
        gene = {id = id, value = value}
        table.insert(unit_export_data.appearance.genes.colors, gene)
    end
end

function get_unit_metadata(unit)
    unit_export_data.name = unit.name.first_name
    unit_export_data.race = unit.race
    unit_export_data.sex = unit.sex
    unit_export_data.profession = unit.profession
    unit_export_data.profession2 = unit.profession2
end

-- Export process

function data_preview(export_data)
    print("\nExporting adventurer with the following data...\n")

    print("name: " .. export_data.name)
    print("race: " .. export_data.race)
    print("sex: " .. export_data.sex)
    print("profession: " .. export_data.profession)
    print("profession2: " .. export_data.profession2)

    print("\n--------------\nBODY ATTRIBUTES\n--------------")
    for i, attribute in ipairs(export_data.body_attributes) do
        print(attribute:toString())
    end
    print("\n--------------\nMENTAL ATTRIBUTES\n--------------")
    for i, attribute in ipairs(export_data.mental_attributes) do
        print(attribute:toString())
    end

    print("--------------\nSKILLS\n--------------")
    for i, skill in ipairs(export_data.skills) do
        print(skill:toString())
    end
end

-- Check if a folder with this name could be created or already exists
function create_folder(folder_name)
    -- check if it is a file, not a folder
    if dfhack.filesystem.isfile(folder_name) then
        qerror(folder_name .. " is a file, not a folder")
    end
    if dfhack.filesystem.exists(folder_name) then
        return true
    else
        return dfhack.filesystem.mkdir(folder_name)
    end
end

-- Get the date of the world as a string
-- Format: "YYYYY-MM-DD"
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
    get_unit_metadata(target)
    data_preview(unit_export_data)
    export_to_json(unit_export_data)
end

export_adv()
