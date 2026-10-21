local LampController = {}
LampController.__index = LampController

function LampController:new(scene, auvController)
    local instance = setmetatable({}, LampController)
    instance:init(scene)
    instance.auvController = auvController
    return instance
end

function LampController:init(scene)
    self.poolLamp1 = scene:GetChild("poolLamp1", true)
    self.poolLamp2 = scene:GetChild("poolLamp2", true)
end

function LampController:UpdateLampBillboard(lampObject)
    if lampObject == nil then
        return
    end
    
    local auvPos = self.auvController:GetWorldPosition()
    local lampPos = lampObject:GetWorldPosition()
    local dist = (lampPos - auvPos):Length()

    if dist < 0.6 then
        local minBias = 0.001
        local maxBias = -0.015
        local maxDist = 0.6

        local bias = maxBias + (minBias - maxBias) * math.max(0, (maxDist - dist)/maxDist)

        local billboardNode = lampObject:GetChild("Billboard")

        if billboardNode ~= nil then
            local billboard = billboardNode:GetComponent("BillboardSet")
            local mat = billboard:GetMaterial()

            local biasParams = BiasParameters:new()

            biasParams.constantBias = bias
            biasParams.slopeScaledBias = 0.0

            mat:SetDepthBias(biasParams)
        end
    end
end

function LampController:update()
    self:UpdateLampBillboard(self.poolLamp1)
    self:UpdateLampBillboard(self.poolLamp2)
end

return LampController