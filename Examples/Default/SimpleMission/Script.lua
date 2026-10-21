local ParticlesController = require("Scripts/ParticlesController")
local LampController = require("Scripts/LampController")
local SceneSettings = require("Scripts/SceneSettings")
local AuvSettings = require("Scripts/AuvSettings")

Script = ScriptObject()

function Script:InitObjects()
    self.scene = self.node:GetScene()

    self.auvSettings = AuvSettings:new(self.scene)
    self.particlesController = ParticlesController:new(self.scene, self.auvSettings)
    self.lampController = LampController:new(self.scene, self.auvSettings)
    self.sceneSettings = SceneSettings:new(self.particlesController)
end


function Script:Update(timeStep)
    self.particlesController:update(timeStep)
    self.lampController:update()
end

function Script:OnChangeSceneSettings(event, args)
    self.sceneSettings:ChangeSceneSettings(event, args)
end

function Script:Start()
    self:InitObjects()
    self.auvSettings:SetMotorsFactorAndOffset()
    self.sceneSettings:SendSceneSettings()
    self:SubscribeToEvent("CHANGE_SCENE_SETTINGS", "Script:OnChangeSceneSettings")
end
