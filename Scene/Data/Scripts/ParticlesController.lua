ParticlesController = {}
ParticlesController.__index = ParticlesController 

function ParticlesController:new(scene, auvController)
    local instance = setmetatable({}, self)
    instance:init(scene)
    instance:enableEmitting(true)
    instance.auvController = auvController
    return instance
end

function ParticlesController:init(scene)
    local particlesXml = cache:GetResource("XMLFile", "Nodes/Environment/Particles/Particles.xml")
    if particlesXml then
        self.particles = scene:InstantiateXML(particlesXml:GetRoot(), Vector3.ZERO, Quaternion())
    end

    local bubblesXml = cache:GetResource("XMLFile", "Nodes/Environment/Particles/Bubbles.xml")
    if bubblesXml then
        self.bubbles = scene:InstantiateXML(bubblesXml:GetRoot(), Vector3.ZERO, Quaternion())
    end
end

function ParticlesController:enableEmitting(enable)
    self.particles:GetComponent("ParticleEmitter"):SetEmitting(enable);
    self.bubbles:GetComponent("ParticleEmitter"):SetEmitting(enable);
end

function ParticlesController:isParticlesEnabled()
    return self.particles:IsEnabled()
end

function ParticlesController:isBubblesEnabled()
    return self.bubbles:IsEnabled()
end

function ParticlesController:setParticlesEnabled(enabled)
    self.particles:SetEnabled(enabled)
end

function ParticlesController:setBubblesEnabled(enabled)
    self.bubbles:SetEnabled(enabled)
end

function ParticlesController:setParticlesScale(scale)
    self.particles:SetScale(Vector3(scale, scale, scale))
end

function ParticlesController:getParticlesScale()
    return self.particles:GetScale().x
end

function ParticlesController:particlesGeneric()
    local scale = 1.5;
    local auvPos = self.auvController:GetPosition()

    local pos = auvPos + Vector3(
        Random(scale * 2) - scale,
        Random(scale * 2) - scale,
        Random(scale * 2) - scale
    )

    self.particles:SetWorldPosition(pos);
end

function ParticlesController:particlesBubbles(timestep)
    local scale = 0.1;
    local auvPos = self.auvController:GetPosition()

    if self.auvBubblesFactor == nil then
        self.auvBubblesFactor = 0.0
    end

    if (auvPos.y > -0.05) then
        self.auvBubblesFactor = 1.0
    end

    self.auvBubblesFactor = self.auvBubblesFactor * (1.0 - timestep)
    self.auvBubblesFactor = Min(self.auvBubblesFactor, 1.0)
    self.auvBubblesFactor = Max(self.auvBubblesFactor, 0.0002)

    pos = auvPos + Vector3(
        Random(scale * 2) - scale,
        Random(scale * 2) - scale,
        Random(scale * 2) - scale
    )

    self.bubbles:SetWorldPosition(pos);

    bubblesEffect = self.bubbles:GetComponent("ParticleEmitter"):GetEffect()
    local bubblesEmission = self.auvBubblesFactor * 500
    bubblesEffect:SetMinEmissionRate(bubblesEmission)
    bubblesEffect:SetMaxEmissionRate(bubblesEmission)
end

function ParticlesController:update(timestep)
    self:particlesGeneric()
    self:particlesBubbles(timestep)
end

return ParticlesController