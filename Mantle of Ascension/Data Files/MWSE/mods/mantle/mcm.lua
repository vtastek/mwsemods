local config = require("mantle.config")

local template = mwse.mcm.createTemplate{name="Mantle of Ascension"}
template:saveOnClose("mantle", config)
template:register()

local generalPage = template:createSideBarPage{
    label = "Mantle of Ascension Settings",
    description = "General settings Mantle of Ascension, v0.0.1",
}

generalPage:createYesNoButton{
    label = "Train Acrobatics",
    description = "Climbing will increase Acrobatics skill...",
    variable = mwse.mcm.createTableVariable({id = "trainAcrobatics", table = config})
}
generalPage:createYesNoButton{
    label = "Train Athletics",
    description = "Climbing will increase Athletics skill...",
    variable = mwse.mcm.createTableVariable({id = "trainAthletics", table = config})
}

local skillModule = include("OtherSkills.skillModule")
if skillModule ~= nil then
    generalPage:createYesNoButton{
        label = "Train Climbing",
        description = "Climbing will increase its own Climbing skill...",
        variable = mwse.mcm.createTableVariable({id = "trainClimbing", table = config})
    }
else
    generalPage:createHyperlink{
        label = "You can get Skills Module to add Climbing Skill too!",
        description = "Installing Skills Module will add Climbing skill as default.",
        text = "https://www.nexusmods.com/morrowind/mods/46034",
        exec = 'start https://www.nexusmods.com/morrowind/mods/46034'
    }
end

generalPage:createYesNoButton{
    label = "Disable Third Person",
    description = "Third Person lacks animations, also Morrowind's janky physics makes it undesirable.",
    variable = mwse.mcm.createTableVariable({id = "disableThirdPerson", table = config})
}
