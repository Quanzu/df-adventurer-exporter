-- Export adventurer data into an XML file for use in importadv script.
-- Script version: v0.1.0
--[====[

exportadv
=============
Export adventurer data into an XML file for use in importadv script.

Currently, this script only exports adventurer skills, attributes, and professions.
Future iterations will hopefully be able to export more data to more accurately
reconstruct an adventurer.

Usage::

    exportadv

]====]

-- Attribute Class
Attribute = {}
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
Skill = {}
Skill.__index = Skill

function Skill:new(id, rating, experience)
    this = {
        id = id or 0,
        rating = rating or 0,
        experience = experience or 0
    }
    setmetatable(this, Skill)
    return this
end

function Skill:getName()
    -- This table is based off https://dwarffortresswiki.org/index.php/DF2014:Skill_token
    local lookupTable = {
        [0] = "MINING",
        "WOODCUTTING",
        "CARPENTRY",
        "DETAILSTONE",
        "MASONRY",
        "ANIMALTRAIN",
        "ANIMALCARE",
        "DISSECT_FISH",
        "DISSECT_VERMIN",
        "PROCESSFISH",
        "BUTCHER",
        "TRAPPING",
        "TANNER",
        "WEAVING",
        "BREWING",
        "ALCHEMY",
        "CLOTHESMAKING",
        "MILLING",
        "PROCESSPLANTS",
        "CHEESEMAKING",
        "MILK",
        "COOK",
        "PLANT",
        "HERBALISM",
        "FISH",
        "SMELT",
        "EXTRACT_STRAND",
        "FORGE_WEAPON",
        "FORGE_ARMOR",
        "FORGE_FURNITURE",
        "CUTGEM",
        "ENCRUSTGEM",
        "WOODCRAFT",
        "STONECRAFT",
        "METALCRAFT",
        "GLASSMAKER",
        "LEATHERWORK",
        "BONECARVE",
        "AXE",
        "SWORD",
        "DAGGER",
        "MACE",
        "HAMMER",
        "SPEAR",
        "CROSSBOW",
        "SHIELD",
        "ARMOR",
        "SIEGECRAFT",
        "SIEGEOPERATE",
        "BOWYER",
        "PIKE",
        "WHIP",
        "BOW",
        "BLOWGUN",
        "THROW",
        "MECHANICS",
        "MAGIC_NATURE",
        "SNEAK",
        "DESIGNBUILDING",
        "DRESS_WOUNDS",
        "DIAGNOSE",
        "SURGERY",
        "SET_BONE",
        "SUTURE",
        "CRUTCH_WALK",
        "WOOD_BURNING",
        "LYE_MAKING",
        "SOAP_MAKING",
        "POTASH_MAKING",
        "DYER",
        "OPERATE_PUMP",
        "SWIMMING",
        "PERSUASION",
        "NEGOTIATION",
        "JUDGING_INTENT",
        "APPRAISAL",
        "ORGANIZATION",
        "RECORD_KEEPING",
        "LYING",
        "INTIMIDATION",
        "CONVERSATION",
        "COMEDY",
        "FLATTERY",
        "CONSOLE",
        "PACIFY",
        "TRACKING",
        "KNOWLEDGE_ACQUISITION",
        "CONCENTRATION",
        "DISCIPLINE",
        "SITUATIONAL_AWARENESS",
        "WRITING",
        "PROSE",
        "POETRY",
        "READING",
        "SPEAKING",
        "COORDINATION",
        "BALANCE",
        "LEADERSHIP",
        "TEACHING",
        "MELEE_COMBAT",
        "RANGED_COMBAT",
        "WRESTLING",
        "BITE",
        "GRASP_STRIKE",
        "STANCE_STRIKE",
        "DODGING",
        "MISC_WEAPON",
        "KNAPPING",
        "MILITARY_TACTICS",
        "SHEARING",
        "SPINNING",
        "POTTERY",
        "GLAZING",
        "PRESSING",
        "BEEKEEPING",
        "WAX_WORKING",
        "CLIMBING",
        "GELD",
        "DANCE",
        "MAKE_MUSIC",
        "SING",
        "PLAY_KEYBOARD_INSTRUMENT",
        "PLAY_STRINGED_INSTRUMENT",
        "PLAY_WIND_INSTRUMENT",
        "PLAY_PERCUSSION_INSTRUMENT",
        "CRITICAL_THINKING1",
        "LOGIC",
        "MATHEMATICS",
        "ASTRONOMY",
        "CHEMISTRY",
        "GEOGRAPHY",
        "OPTICS_ENGINEER",
        "FLUID_ENGINEER",
        "PAPERMAKING",
        "BOOKBINDING1",
        "INTRIGUE",
        "RIDING"
    }

    return lookupTable[self.id]
end

function Skill:toString()
    return string.format(
        "name: %30s, id: %4d, rating: %4d, experience: %d",
        self:getName(),
        self.id,
        self.rating,
        self.experience
    )
end

-- Unit parsing
unit_export_data = {name = "default", profession = -1, profession2 = -1, skills = {}, attributes = {}}

function get_unit_attributes(target)
    if target == nil then
        print("No unit available!")
        return
    end
    local unit = target

    for attribute_name, attribute in pairs(unit.body.physical_attrs) do
        attr_data = Attribute:new(attribute_name, attribute.value, attribute.max_value)
        table.insert(unit_export_data.attributes, attr_data)
    end

    for attribute_name, attribute in pairs(unit.status.current_soul.mental_attrs) do
        attr_data = Attribute:new(attribute_name, attribute.value, attribute.max_value)
        table.insert(unit_export_data.attributes, attr_data)
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

    print("\n--------------\nATTRIBUTES\n--------------")
    for i, attribute in ipairs(export_data.attributes) do
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

function export_to_xml(export_data)
    local folder_name = "exported_adventurers"
    local file_name =
        export_data.name ..
        "-" .. df.global.world.cur_savegame.save_dir .. "-" .. get_world_date_str() .. "-adventurer.xml"
    local full_file_path = folder_name .. "/" .. file_name

    if not create_folder(folder_name) then
        qerror("The foldername " .. folder_name .. " could not be created")
    end

    if not move_to_folder(folder_name) then
        qerror("Could not move into folder: " .. folder_name)
    end

    local file = io.open(file_name, "w")
    move_back_to_main_folder()
    if not file then
        qerror("could not open file: " .. full_file_path)
    end

    print(string.format("\nWriting to %s ...", full_file_path))
    file:write('<?xml version="1.0" encoding=\'UTF-8\'?>\n')
    file:write("<adventurer>\n")

    file:write("\t<metadata>\n")
    file:write("\t\t<name>\n" .. export_data.name .. "\t\t</name>\n")
    file:write("\t\t<profession>\n" .. export_data.profession .. "\t\t</profession>\n")
    file:write("\t\t<profession2>\n" .. export_data.profession2 .. "\t\t</profession2>\n")
    file:write("\t</metadata>\n")

    file:write("\t<attributes>\n")
    for i, attribute in ipairs(export_data.attributes) do
        file:write("\t\t<attribute>\n")
        file:write("\t\t\t<name>\n" .. attribute.name .. "\t\t\t</name>\n")
        file:write("\t\t\t<value>\n" .. attribute.value .. "\t\t\t</value>\n")
        file:write("\t\t\t<max_value>\n" .. attribute.max_value .. "\t\t\t</max_value>\n")
        file:write("\t\t</attribute>\n")
    end
    file:write("\t</attributes>\n")

    file:write("\t<skills>\n")
    for i, skill in ipairs(export_data.skills) do
        file:write("\t\t<skill>\n")
        file:write("\t\t\t<id>" .. skill.id .. "\t\t\t</id>")
        file:write("\t\t\t<rating>" .. skill.rating .. "\t\t\t</rating>")
        file:write("\t\t\t<experience>" .. skill.experience .. "\t\t\t</experience>")
        file:write("\t\t</skill>\n")
    end
    file:write("\t</skills>\n")

    file:write("</adventurer>\n")
    file:close()
    print("Done!")
end

function export_adv()
    local target = df.global.world.units.active[0]
    get_unit_attributes(target)
    get_unit_skills(target)
    get_unit_metadata(target)
    data_preview(unit_export_data)
    export_to_xml(unit_export_data)
end

export_adv()
