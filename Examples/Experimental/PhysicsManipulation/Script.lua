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

    self.colorCube = self.scene:GetChild("colorCube", true)
end


function Script:Update(timeStep)
    self.particlesController:update(timeStep)
    self.lampController:update()
    self:ChangeCubeColor()
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

--- COLLISION CHECK
function Script:BodyCollisionCheck(body, targetTag, hitTag)
    if body:HasTag("hit_floor") then
        return false
    end

    local rigidBody = body:GetComponent("RigidBody")
    if rigidBody == nil then
        return false
    end

    local physicsWorld = self.scene:GetComponent("PhysicsWorld")
    local collidingBodies = physicsWorld:GetCollidingBodies(rigidBody)

    for _, item in pairs(collidingBodies) do
        local node = item:GetNode()

        if node ~= nil and node:HasTag(targetTag) then
            if hitTag ~= "" then
                body:AddTag(hitTag)
            end

            return true
        end
    end

    return false
end

function Script:CollisionOfTwo(item_name, target_tag, shootObj_tag, checkTag)
    if checkTag == nil then
        checkTag = false
    end

    local nodes = self.scene:GetChildren(true)

    for _, item in pairs(nodes) do
        if item:GetName() == item_name then
            if not checkTag or not item:HasTag(shootObj_tag) then
                if self:BodyCollisionCheck(item, target_tag, shootObj_tag) then
                    return true
                end
            end
        end
    end

    return false
end

function Script:ChangeCubeColor()
    if self:CollisionOfTwo("Button", "button_trigger", "") then
        self.colorCube:GetComponent("StaticModel"):SetMaterial(
            cache:GetResource(
                "Material",
                "Materials/Objects/Colors/Green.xml"
            )
        )
    else
        self.colorCube:GetComponent("StaticModel"):SetMaterial(
            cache:GetResource(
                "Material",
                "Materials/Objects/Colors/Magenta.xml"
            )
        )
    end
end