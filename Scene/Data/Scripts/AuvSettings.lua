AuvSettings = {}
AuvSettings.__index = AuvSettings

function AuvSettings:new(scene)
    local instance = setmetatable({}, self)
    instance:init(scene)
    return instance
end

function AuvSettings:init(scene)
    self.auv = scene:GetChild("AUV", true)
end

function AuvSettings:SetMotorsFactorAndOffset()
    local data = VariantMap()

    -- offset = RandomInt(-5, 5)
    -- factor = Random(-0.05, 0.05)

    data["offset_fl"] = 0
    data["offset_fr"] = 0
    data["offset_tl"] = 0
    data["offset_tr"] = 0
    data["offset_b"] = 0

    data["factor_fl"] = 0
    data["factor_fr"] = 0
    data["factor_tl"] = 0
    data["factor_tr"] = 0
    data["factor_b"] = 0

    SendEvent("MOTOR_FACTOR_N_OFFSET", data)
end

function AuvSettings:GetPosition()
    return self.auv:GetPosition()
end

function AuvSettings:GetWorldPosition()
    return self.auv:GetWorldPosition()
end

return AuvSettings