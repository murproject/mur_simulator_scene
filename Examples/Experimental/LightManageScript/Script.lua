local ParticlesController = require("Scripts/ParticlesController")
local LampController = require("Scripts/LampController")
local AuvSettings = require("Scripts/AuvSettings")

Script = ScriptObject()

function Script:InitObjects()
    self.scene = self.node:GetScene()

    self.auvSettings = AuvSettings:new(self.scene)
    self.particlesController = ParticlesController:new(self.scene, self.auvSettings)
    self.lampController = LampController:new(self.scene, self.auvSettings)

    self.scene = self.node:GetScene()
    self.objs = {}

    self.nodes = self.scene:GetChildren(true)

    self.objs_names = {
        sunlight = "sunlight"
    }

    for key, item in pairs(self.nodes) do
        local node_name = item:GetName()
        local obj_name = self.objs_names[node_name]

        if obj_name ~= nil then
            self.objs[obj_name] = item
        end
    end
end

function Script:convertTableToVariantMap(luaTable)
    local variantMap = VariantMap()
    
    for key, value in pairs(luaTable) do
        if type(value) == "table" then
            variantMap[key] = self:convertTableToVariantMap(value)
        else
            variantMap[key] = value
        end
    end
    return variantMap
end

function Script:SendSceneSettings()
    local rot = self.objs.sunlight:GetRotation()
    local pos = self.objs.sunlight:GetPosition()
    
    local sceneSettings = {
        {
            type = "slider",
            name = "sun_x_rot",
            label = "Sun rotation X: ",
            min = -180,
            max = 180,
            defaultValue = rot.x * 100,
            sliderDivider = 1,
            step = 1
        },

        {
            type = "slider",
            name = "sun_y_rot",
            label = "Sun rotation Y: ",
            min = -180,
            max = 180,
            defaultValue = rot.y * 100,
            sliderDivider = 1,
            step = 1
        },

        {
            type = "slider",
            name = "sun_x_pos",
            label = "Sun position X: ",
            min = -1000,
            max = 1000,
            defaultValue = pos.x * 100,
            sliderDivider = 100,
            step = 1
        },

        {
            type = "slider",
            name = "sun_y_pos",
            label = "Sun position Y: ",
            min = -400,
            max = 500,
            defaultValue = pos.y * 100,
            sliderDivider = 100,
            step = 1
        },

        {
            type = "slider",
            name = "sun_z_pos",
            label = "Sun position Z: ",
            min = -1000,
            max = 1000,
            defaultValue = pos.z * 100,
            sliderDivider = 100,
            step = 1
        },

        {
            type = "slider",
            name = "sun_brightness",
            label = "Sun brightness: ",
            min = 0,
            max = 500,
            defaultValue = self.objs.sunlight:GetComponent("Light"):GetBrightness() * 100,
            sliderDivider = 100,
            step = 1
        },

        {
            type = "checkbox",
            name = "sun_enabled",
            label = "Sun enable: ",
            defaultValue = self.objs.sunlight:IsEnabled()
        },

        {
            type = "checkbox",
            name = "bubbles",
            label = "AUV bubbles",
            defaultValue = self.particlesController:isBubblesEnabled()
        },

        {
            type = "sliderCheckbox",
            name = "particles",
            label = "Particles",
            min = 0,
            max = 100,
            sliderDefaultValue = self.particlesController:getParticlesScale() * 10,
            checkboxDefaultValue = self.particlesController:isParticlesEnabled(),
            sliderDivider = 10
        }
    }
    
    local data = self:convertTableToVariantMap(sceneSettings)

    SendEvent("SCENE_SETTINGS", data)
end

function Script:ChangeSceneSettings(event, args)
    -- sunlight adjust
    if self.objs.sunlight ~= nil then
        local sunlight = self.objs.sunlight
        local rotation = sunlight:GetRotation()
        local position = sunlight:GetPosition()

        local newRotX = args["sun_x_rot"] ~= nil and args["sun_x_rot"]:GetFloat() / 100 or rotation.x
        local newRotY = args["sun_y_rot"] ~= nil and args["sun_y_rot"]:GetFloat() / 100 or rotation.y

        local newPosX = args["sun_x_pos"] ~= nil and args["sun_x_pos"]:GetFloat() or position.x
        local newPosY = args["sun_y_pos"] ~= nil and args["sun_y_pos"]:GetFloat() or position.y
        local newPosZ = args["sun_z_pos"] ~= nil and args["sun_z_pos"]:GetFloat() or position.z

        if args["sun_enabled"] ~= nil then sunlight:SetEnabled(args["sun_enabled"]:GetBool()) end

        if args["sun_brightness"] ~= nil then
            sunlight:GetComponent("Light"):SetBrightness(args["sun_brightness"]:GetFloat())
        end

        sunlight:SetRotation(Quaternion(rotation.w, newRotX, newRotY, rotation.z))
        sunlight:SetPosition(Vector3(newPosX, newPosY, newPosZ))
    end

    -- particles
    if args["particles_checkbox"] ~= nil then
        self.particlesController:setParticlesEnabled(args["particles_checkbox"]:GetBool())
    end

    local intensity = args["particles"]

    if intensity ~= nil then
        self.particlesController:setParticlesScale(intensity:GetFloat())
    end

    -- bubbles
    if args["bubbles"] ~= nil then
        self.particlesController:setBubblesEnabled(args["bubbles"]:GetBool())
    end
end

function Script:Update(timeStep)
    self.particlesController:update(timeStep)
    self.lampController:update()
end

function Script:Start()
    self:InitObjects()
    self.auvSettings:SetMotorsFactorAndOffset()
    self:SendSceneSettings()
    self:SubscribeToEvent("CHANGE_SCENE_SETTINGS", "Script:ChangeSceneSettings");
end
