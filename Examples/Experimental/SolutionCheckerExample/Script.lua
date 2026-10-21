local ParticlesController = require("Scripts/ParticlesController")
local LampController = require("Scripts/LampController")
local SceneSettings = require("Scripts/SceneSettings")
local AuvSettings = require("Scripts/AuvSettings")

SolutionChecker = {}
SolutionChecker.__index = SolutionChecker

function SolutionChecker:new(scene)
    local instance = setmetatable({}, SolutionChecker)
    instance:init(scene)
    self.scene = scene
    return instance
end

function SolutionChecker:init(scene)
    self.black_box = scene:GetChild("black_box", true)
    self.auv = scene:GetChild("AUV", true)
end

-- START SCRIPT EVENT

function SolutionChecker:PrepareInvisibleObjs()
    local invisible_objs = self.scene:GetChildrenWithTag("i", true)

    for key, item in pairs(invisible_objs) do
        item:GetComponent("StaticModel"):SetViewMask(0)
    end
end

function SolutionChecker:InitProps()
    -- SCRIPT UPDATE VARS
    -- time count
    self.solution_log_timestamp = Time:GetSystemTime()
    self.time_passed = 0
    self.solution_timelimit = 300
    -- score
    self.solution_score_log = ""
    self.total_score = 0
    -- finish
    self.finish_reason = "Неизвестно"
    self.isFinished = false
    self.finish_time = 0

    -- SPECIFIC SCENE VARS
    -- visit figures
    self.visit_score = 0
    self.correct_visits = {}
    self.prev_visit_index = nil
    self.visit_names = {
        [1] = "Круг",
        [2] = "Квадрат",
        [3] = "Прямоуг.",
        [4] = "Треуг."
    }
    self.visit_tags = {"visit_circle", "visit_square", "visit_rectangle", "visit_triangle"}

    -- action on objects
    self.circle_score = 0
    self.rect_score = 0
    self.square_score = 0
    self.triangle_score = 0

    self.float_score = 0
    self.circle_drops_count = 0
    self.pinger_index = nil
    self.wrong_bin_colliding = false
end

function SolutionChecker:Start()
    self:InitProps()

    self:PrepareInvisibleObjs()
    self:GetPingerNum()
    self:SetCollisionAlways(self.black_box, 1)
end

function SolutionChecker:TimerStart()
    self.solution_log_timestamp = Time:GetSystemTime()
end

-- UPDATE SCRIPT EVENT

function SolutionChecker:Update(timeStep)
    self.time_passed = Floor((Abs(Time:GetSystemTime() - self.solution_log_timestamp)) / 1000)
    self:FillLog()

    if not self.isFinished then
        if (self.time_passed > 3) then
            self:isFinalCheck()
            self:FinalFloatScore()
        end

        self:VisitScore()
        self:ActionOnFig()

        self.total_score = self.visit_score + self.float_score + self.circle_score + self.rect_score + self.square_score + self.triangle_score

        self.solution_score_log = 
            logString("", "") .. 
            logString("Посещение фигур: ", self.visit_score) ..
            logString("- ", self:GetVisitString()) ..
            logString("Действия", "") ..
            logString("- Круг: ", self.circle_score .. ". Сброшено маркеров: " .. self.circle_drops_count) ..
            logString("- Квадрат: ", self.square_score) ..
            logString("- Прямоугольник: ", self.rect_score) ..
            logString("- Треугольник: ", self.triangle_score) ..
            logString("Всплытие: ", self.float_score)

        self.finish_time = self.time_passed
    end

    if self.isFinished then
        if self.time_passed > self.finish_time + 3 then
            self:Final()
        end
    end
end

function SolutionChecker:FillLog()
    local output = Variant(self.total_score .. '\n\n\n' .. self.finish_time .. '\n\n\n'  .. self.solution_score_log .. '\n\n\n'  .. self.finish_reason) 

    local data = VariantMap()
    data["OUTPUT"] = output

    SendEvent("SOLUTION_CHECKER_OUTPUT", data);
end

function logString(key, value)
    local stroke = key .. tostring(value)  .. '\n'
    return stroke
end

-- SCRIPT FINAL EVENT
function SolutionChecker:Final()
    local output = Variant(self.total_score .. '\n\n\n' .. self.finish_time .. '\n\n\n'  .. self.solution_score_log .. '\n\n\n' .. self.finish_reason)

    local data = VariantMap()
    data["FINAL"] = output

    SendEvent("SOLUTION_CHECKER_FINISH", data);
end

function SolutionChecker:isFinalCheck()
    local auvBody = self.auv:GetComponent("RigidBody")
    local surfaced = auvBody:GetPosition().y > -0.06

    if surfaced then
        self.finish_reason = "Аппарат всплыл"
        self.isFinished = true
    end

    if (self.time_passed >= self.solution_timelimit) then
        self.finish_reason = "Время вышло"
        self.isFinished = true
    end

    if self.float_score == 5 then
        self.finish_reason = "Аппарат всплыл в неверной рамке"
        self.isFinished = true
    end


    if self.float_score == 15 then
        self.finish_reason = "Аппарат всплыл в верной рамке"
        self.isFinished = true
    end
end

function SolutionChecker:FinalFloatScore()
    if self.float_score == 0 then 
        if self:CollisionOfTwo("AUV", "wrong_frame", "") then
            self.float_score = 5
        end

        if self:CollisionOfTwo("AUV", "correct_frame", "") then
            self.float_score = 15
        end
    end
end

--- OBJECTS COLLISION
function SolutionChecker:SetCollisionAlways(obj, state)
    obj:GetComponent("RigidBody"):SetCollisionEventMode(state and COLLISION_ALWAYS or COLLISION_ACTIVE)
end

function SolutionChecker:BodyCollisionCheck(body, targetTag, hitTag)
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
        if node ~= nil then
            if node:HasTag(targetTag) then
                if hitTag ~= "" then
                    body:AddTag(hitTag)
                end
                
                return true
            end
        end
    end

    return false
end

function SolutionChecker:CollisionOfTwo(item_name, target_tag, shootObj_tag, checkTag)
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

-- CHECK TASKS
function SolutionChecker:GetPingerNum()
    for i = 0, 4 do
        local name = "Pinger_" .. i
        local node = self.scene:GetChild(name, true)

        if node ~= nil then
            self.pinger_index = i + 1
            return
        end
    end

    self.pinger_index = 0 
end

function SolutionChecker:TotalDrops()
    local nodes = self.scene:GetChildren(true)
    local shoots = 0

    for key, item in pairs(nodes) do
        if item:GetName() == "DropObject" then
            shoots = shoots + 1
        end
    end
    return shoots
end

function SolutionChecker:ActionOnFig()
    local drop_count = self:TotalDrops()

    -- drop objects equal pinger num on circle
    if self:CollisionOfTwo("DropObject", "circle_collision", "processed", true) then
        self.circle_drops_count = self.circle_drops_count + 1
        if self.circle_drops_count == self.pinger_index then
            self.circle_score = 10
        else
            self.circle_score = 0
        end
    end

    -- remove black box from rectangle
    if self:CollisionOfTwo("black_box", "rect_collision", "") then
        self.rect_score = 0
    else 
        self.rect_score = 15
    end

    -- drop objects to biggest white bin near square
    if self.square_score == 0 and not self.wrong_bin_colliding then
        if self:CollisionOfTwo("DropObject", "wrong_bin", "") then
            self.wrong_bin_colliding = true
        end
        if self:CollisionOfTwo("DropObject", "square_collision", "") then
            self.square_score = 15
        end
    end

    -- touch triangle with auv
    if self.triangle_score == 0 then
        if self:CollisionOfTwo("AUV", "triangle_collision", "") then
            self.triangle_score = 15
        end
    end
end

-- VISIT ORDER CHECK
function SolutionChecker:UpdateVisitCollision()
    local current_visit = nil

    for i = 1,4 do
        if self:CollisionOfTwo("AUV", self.visit_tags[i], "", false) then
            current_visit = i
            break
        end
    end

    if current_visit ~= nil and current_visit ~= self.prev_visit_index then
        table.insert(self.correct_visits, current_visit) 
    end

    if current_visit == nil then
        self.prev_visit_index = nil
    else
        self.prev_visit_index = current_visit
    end
end

function SolutionChecker:VisitScore()
    self:UpdateVisitCollision()

    local correct_route = {1, 2, 3, 4}
    local max_correct = 0

    for i = 1, math.min(#self.correct_visits, 4) do
        if self.correct_visits[i] == correct_route[i] then
            max_correct = max_correct + 1
        else
            break
        end
    end

    if max_correct == 1 then
        self.visit_score = 0
    elseif max_correct == 2 then
        self.visit_score = 10
    elseif max_correct == 3 then
        self.visit_score = 20
    elseif max_correct >= 4 then
        self.visit_score = 30
    else
        self.visit_score = 0
    end
end

function SolutionChecker:GetVisitString()
    local result = {}

    for i = 1,4 do
        local name = self.visit_names[self.correct_visits[i]]

        if name then
            if i > 1 then
                result[i] = " → " .. name
            else
                result[i] = name
            end
        else
            result[i] = ""
        end
    end

    return table.concat(result, "")
end

-- DEFAULT SCRIPT
Script = ScriptObject()

function Script:InitObjects()
    self.scene = self.node:GetScene()

    self.auvSettings = AuvSettings:new(self.scene)
    self.particlesController = ParticlesController:new(self.scene, self.auvSettings)
    self.lampController = LampController:new(self.scene, self.auvSettings)
    self.sceneSettings = SceneSettings:new(self.particlesController)
    self.solutionChecker = SolutionChecker:new(self.scene)
end


function Script:Update(timeStep)
    self.particlesController:update(timeStep)
    self.lampController:update()
    self.solutionChecker:Update(timeStep)
end

function Script:OnChangeSceneSettings(event, args)
    self.sceneSettings:ChangeSceneSettings(event, args)
end

function Script:StartSolutiuonChecker()
    self.solutionChecker:TimerStart()
end

function Script:Start()
    self:InitObjects()
    self.auvSettings:SetMotorsFactorAndOffset()
    self.sceneSettings:SendSceneSettings()
    self.solutionChecker:Start()
    self:SubscribeToEvent("CHANGE_SCENE_SETTINGS", "Script:OnChangeSceneSettings")
    self:SubscribeToEvent("SOLUTION_CHECKER_START", "Script:StartSolutiuonChecker")
end