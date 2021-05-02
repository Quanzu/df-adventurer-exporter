-- Export adventurer data into an JSON file for use in importadv script.
-- Script version: v0.1.0
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
    profession = -1,
    profession2 = -1,
    skills = {},
    body_attributes = {},
    mental_attributes = {}
}

function get_unit_attributes(target)
    if target == nil then
        print("No unit available!")
        return
    end
    local unit = target

    for attribute_name, attribute in pairs(unit.body.physical_attrs) do
        attr_data = Attribute:new(attribute_name, attribute.value, attribute.max_value)
        table.insert(unit_export_data.body_attributes, attr_data)
    end

    for attribute_name, attribute in pairs(unit.status.current_soul.mental_attrs) do
        attr_data = Attribute:new(attribute_name, attribute.value, attribute.max_value)
        table.insert(unit_export_data.mental_attributes, attr_data)
    end
end

function get_unit_skills(target)
    if target == nil then
        print("No unit available!")
        return
    end
    local unit = target

    for index, skill in ipairs(unit.status.current_soul.skills) do
        local skill_data = Skill:new(skill.id, skill.rating, skill.experience)
        table.insert(unit_export_data.skills, skill_data)
    end
end

function get_unit_metadata(target)
    if target == nil then
        print("No unit available!")
        return
    end
    local unit = target

    -- Note that the name is only used for the exported file name.
    unit_export_data.name = unit.name.first_name
    unit_export_data.profession = unit.profession
    unit_export_data.profession2 = unit.profession2
end

-- Export process

function data_preview(export_data)
    print("\nExporting adventurer with the following data...\n")

    print("name: " .. export_data.name)
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

-- Go back to root folder so dfhack does not break, returns true if successfully
function move_back_to_main_folder()
    return dfhack.filesystem.restore_cwd()
end

-- Go to specified folder, returns true if successful
function move_to_folder(folder)
    if move_back_to_main_folder() then
        return dfhack.filesystem.chdir(folder)
    end
    return false
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
    get_unit_attributes(target)
    get_unit_skills(target)
    get_unit_metadata(target)
    data_preview(unit_export_data)
    export_to_json(unit_export_data)
end

export_adv()
