function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end

local shaders = {}

local function GetShaders()
	local file = io.open("mge3/MGE.ini","r");

    local i = 0
    local parse = false
    local s = 0
    if file then
        for line in file:lines() do
            i = i + 1
            if line == '[Shader Chain]' then
                parse = true
                s = 1
            end
            if line == '' then
                parse = false
            end

            if parse and line ~= '[Shader Chain]' then
                if line ~= '' or line ~= nil then
                    shaders[s] = {name=line, state=1}
                    s = s + 1
                end
            end
        end

        file:close();
    else
        error('file not found')
    end
end

GetShaders()


local this = {}

local menu = nil
local openmenu = nil


function this.init()
    this.id_menu = tes3ui.registerID("example:MenuTextInput")
    this.id_cancel = tes3ui.registerID("example:MenuTextInput_Cancel")
    this.id_ListBlock = tes3ui.registerID("example:Shaders_Block")
    this.id_slabels = tes3ui.registerID("example:Shader_Labels")
    event.register("keyDown", this.selUp, {filter=tes3.scanCode.keyUp})
    event.register("keyDown", this.selDown, {filter=tes3.scanCode.keyDown})
    event.register("keyDown", this.selLeft, {filter=tes3.scanCode.keyLeft})
    event.register("keyDown", this.selRight, {filter=tes3.scanCode.keyRight})
    openmenu = false
end


-- Create window and layout. Called by onCommand.
function this.createWindow()
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end

    -- Create window and frame
    menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
    -- To avoid low contrast, text input windows should not use menu transparency settings
    menu.alpha = 1.0
    menu:setPropertyInt("sel", 1)
    menu.absolutePosAlignX = 1.0

    -- Creat Block
    local nameBlock = menu:createBlock({id = this.id_ListBlock})
    nameBlock.autoHeight = true
	nameBlock.autoWidth = true
	nameBlock.paddingAllSides = 1
    nameBlock.flowDirection = "top_to_bottom"
	nameBlock.autoHeight = true
	nameBlock.autoWidth = true
	--nameBlock.childAlignX = 0.5

    -- Create layout
    local input_label = {}
    local si = 1
    for _ in pairs(shaders) do
        input_label[si] = nameBlock:createLabel{id = this.id_slabels, text = shaders[si].name }
        input_label[si].borderBottom = 5
        if shaders[si].state == 1 then
        input_label[si].color = tes3ui.getPalette("active_color")
        end
        if shaders[si].state == 0 then
            input_label[si].color = tes3ui.getPalette("answer_color")
        end
        input_label[si].alpha = 0.66
        si = si + 1
    end

    menu:setPropertyInt("st", si)

    local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0  -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0  -- right content alignment

    local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }

    -- Events
    button_cancel:register("mouseClick", this.onCancel)

    -- Final setup
    menu:updateLayout()
end

function this.selUp()
    local lmenu = tes3ui.findMenu(this.id_menu)
    local selection = lmenu:getPropertyInt("sel")
    local shaderstotal = lmenu:getPropertyInt("st") - 1
    selection = selection - 1

    if selection == 0 then selection = shaderstotal end

    lmenu:setPropertyInt("sel", selection)

    local shBlock = lmenu:findChild(this.id_ListBlock)
    local children = shBlock.children

    for i, block in pairs(children) do
        local label = block:findChild(this.id_slabels)
		if (i == selection) then
			-- If this is the new index, set it to the active color.
            label.alpha = 1.0
        else
            label.alpha = 0.66
        end
	end

    shBlock:updateLayout()
    lmenu:updateLayout()
end

function this.selDown()
    local lmenu = tes3ui.findMenu(this.id_menu)
    local selection = lmenu:getPropertyInt("sel")
    local shaderstotal = lmenu:getPropertyInt("st") - 1
    selection = selection + 1

    if selection > shaderstotal then selection = 1 end

    lmenu:setPropertyInt("sel", selection)

    local shBlock = lmenu:findChild(this.id_ListBlock)
    local children = shBlock.children

    for i, block in pairs(children) do
        local label = block:findChild(this.id_slabels)
		if (i == selection) then
			label.alpha = 1.0
        else
            label.alpha = 0.66
        end
	end

    shBlock:updateLayout()
    lmenu:updateLayout()
end

function this.selLeft()
    local lmenu = tes3ui.findMenu(this.id_menu)
    local selection = lmenu:getPropertyInt("sel")

    mge.disableShader({shader = shaders[selection].name})
    shaders[selection].state = 0

    local shBlock = lmenu:findChild(this.id_ListBlock)
    local children = shBlock.children

    for i, block in pairs(children) do
		if (i == selection) then
			-- If this is the new index, set it to the active color.
			local label = block:findChild(this.id_slabels)
			label.color = tes3ui.getPalette("answer_color")
        end
	end

    shBlock:updateLayout()
    lmenu:updateLayout()
end

function this.selRight()
    local lmenu = tes3ui.findMenu(this.id_menu)
    local selection = lmenu:getPropertyInt("sel")

    mge.enableShader({shader = shaders[selection].name})
    shaders[selection].state = 1

    local shBlock = lmenu:findChild(this.id_ListBlock)
    local children = shBlock.children

    for i, block in pairs(children) do
		if (i == selection) then
			-- If this is the new index, set it to the active color.
			local label = block:findChild(this.id_slabels)
			label.color = tes3ui.getPalette("active_color")
        end
	end

    shBlock:updateLayout()
    lmenu:updateLayout()
end


-- Cancel button callback.
function this.onCancel()
    local lmenu = tes3ui.findMenu(this.id_menu)

    if (lmenu) then
        tes3ui.leaveMenuMode()
        lmenu:destroy()
    end
end


-- Keydown callback.
function this.onCommand()
    if openmenu ~= true then
        this.createWindow()
        openmenu = true
    elseif openmenu then
        this.onCancel()
        openmenu = false
    end
end


event.register("initialized", GetShaders)
event.register("initialized", this.init)
event.register("keyDown", this.onCommand, {filter=tes3.scanCode.v})
