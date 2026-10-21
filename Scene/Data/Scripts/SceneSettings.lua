SceneSettings = {}
SceneSettings.__index = SceneSettings

function SceneSettings:new(particlesController)
    local instance = setmetatable({}, self)
    instance.particlesController = particlesController
    return instance
end

function SceneSettings:convertTableToVariantMap(luaTable)
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

function SceneSettings:SendSceneSettings()
    local sceneSettings = {
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

function SceneSettings:ChangeSceneSettings(event, args)
    -- particles
    if args["particles_checkbox"] ~= nil then 
        self.particlesController:setParticlesEnabled(args["particles_checkbox"]:GetBool()) 
    end

    local intensity = args["particles"]

    if intensity ~= nil then 
        local scale = intensity:GetFloat()
        self.particlesController:setParticlesScale(scale)
    end

    -- bubbles
    if args["bubbles"] ~= nil then 
        self.particlesController:setBubblesEnabled(args["bubbles"]:GetBool()) 
    end
end

return SceneSettings