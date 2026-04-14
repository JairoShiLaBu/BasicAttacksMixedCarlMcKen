local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local DEBRIS = game:GetService("Debris")
local RUN_SERVICE = game:GetService("RunService")
local localPlayer = PLAYERS.LocalPlayer

local ANIM_MAP = {
    ["10469493270"] = "rbxassetid://17325510002",
    ["10469630950"] = "rbxassetid://13491635433",
    ["10469639222"] = "rbxassetid://17889461810",
    ["10469643643"] = "rbxassetid://13294471966"
}

local HITBOX_SIZE = Vector3.new(5, 6, 5)
local HITBOX_OFFSET = 1.0 

-- Hitbox Setup (Invisible)
local visualBox = Instance.new("Part")
visualBox.Name = "ActiveHitbox"
visualBox.Size = HITBOX_SIZE
visualBox.Anchored = true
visualBox.CanCollide = false
visualBox.CanQuery = false
visualBox.Transparency = 1 -- Hitbox is now invisible
visualBox.Parent = workspace

local function spawnPunchVFX(targetHRP)
    if not targetHRP then return end
    
    local emotes = REPLICATED_STORAGE:FindFirstChild("Emotes")
    if not emotes then return end
    
    local source = emotes:FindFirstChild("Punchbarrage", true)
    if not source then return end
    
    local clone = source:Clone()
    
    -- Handle both BaseParts and Attachments
    if clone:IsA("BasePart") then
        clone.CFrame = targetHRP.CFrame
        clone.Anchored = false
        clone.CanCollide = false
        clone.Parent = targetHRP 
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = targetHRP
        weld.Part1 = clone
        weld.Parent = clone
    elseif clone:IsA("Attachment") then
        clone.Parent = targetHRP
    end

    for _, child in ipairs(clone:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            child:Emit(15)
            child.Enabled = true
        end
    end
    
    DEBRIS:AddItem(clone, 2)
end

local function getHitTarget(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -HITBOX_OFFSET)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, visualBox}
    
    local parts = workspace:GetPartBoundsInBox(hitboxCFrame, HITBOX_SIZE, params)
    
    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character then
            local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
            local enemyHRP = model:FindFirstChild("HumanoidRootPart")
            if enemyHumanoid and enemyHRP then
                return enemyHRP
            end
        end
    end
    return nil
end

local function handleCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    
    -- Keep hitbox CFrame updated even if invisible
    RUN_SERVICE.RenderStepped:Connect(function()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp and visualBox then
            visualBox.CFrame = hrp.CFrame * CFrame.new(0, 0, -HITBOX_OFFSET)
        end
    end)

    humanoid.AnimationPlayed:Connect(function(track)
        local idOnly = track.Animation.AnimationId:match("%d+")
        
        if ANIM_MAP[idOnly] then
            track:Stop(0)
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = ANIM_MAP[idOnly]
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0)
            
            task.spawn(function()
                -- 1. Initial delay (Wait 0.1s for anim wind-up)
                task.wait(0.1)
                
                local scanStartTime = tick()
                local vfxTriggered = false
                
                -- 2. Scan window (Check for target for next 0.3s)
                while (tick() - scanStartTime) < 0.3 do
                    local enemyHRP = getHitTarget(character)
                    
                    if enemyHRP and not vfxTriggered then
                        spawnPunchVFX(enemyHRP)
                        vfxTriggered = true 
                        break 
                    end
                    
                    task.wait() 
                end
            end)
        end
    end)
end

if localPlayer.Character then handleCharacter(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(handleCharacter)

local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local DEBRIS = game:GetService("Debris")
local localPlayer = PLAYERS.LocalPlayer

local SKILL_1_OLD = "10470104242" 
local SKILL_1_NEW = "rbxassetid://17858997926"
local SKILL_1_SKIP = 0.6
local SKILL_1_VFX_DELAY = 0.4    
local SKILL_1_VFX_DURATION = 0.2 

local SKILL_2_OLD = "10503381238"
local SKILL_2_NEW = "rbxassetid://14900168720"
local SKILL_2_SKIP = 1.5

local DASH_ANIM_ID = "rbxassetid://10479335397"

local Resources = REPLICATED_STORAGE:WaitForChild("Resources")
local Fang = Resources:WaitForChild("Fang")
local FLASH = Fang:WaitForChild("FLASH")
local flashstep = FLASH:WaitForChild("flashstep")
local VFX_TEMPLATE = flashstep:WaitForChild("Attachment")

local connections = {}

local function cleanup()
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
    table.clear(connections)
end

local function spawnSkillVFX(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local vfxClone = VFX_TEMPLATE:Clone()
    local spawnOffset = hrp.CFrame.LookVector * 5
    local groundLevel = hrp.Position.Y - 3 
    
    vfxClone.Parent = hrp
    vfxClone.WorldPosition = Vector3.new(hrp.Position.X + spawnOffset.X, groundLevel, hrp.Position.Z + spawnOffset.Z)

    for _, child in ipairs(vfxClone:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            child:Emit(15)
            child.Enabled = true
        end
    end

    task.delay(SKILL_1_VFX_DURATION, function()
        for _, child in ipairs(vfxClone:GetChildren()) do
            if child:IsA("ParticleEmitter") then
                child.Enabled = false
            end
        end
        task.wait(1) 
        if vfxClone then vfxClone:Destroy() end
    end)
end

local function spawnDashVFX(hrp)
    local source = REPLICATED_STORAGE.Emotes.VFX.VfxMods.LastWill.vfx.DashFx.Attachment
    local clone = source:Clone()
    
    clone.Parent = hrp
    clone.Position = Vector3.new(0, 0, -2) 
    
    local emitterIndex = 0
    for _, child in ipairs(clone:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            emitterIndex = emitterIndex + 1
            
            if emitterIndex == 1 then
                child:Destroy()
            else
                child:Emit(15)
                child.Enabled = true
            end
        end
    end
    
    DEBRIS:AddItem(clone, 2)
end

local function handleCharacter(character)
    cleanup()

    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")
    
    local animConn = animator.AnimationPlayed:Connect(function(animationTrack)
        local animId = animationTrack.Animation.AnimationId

        if string.find(animId, SKILL_1_OLD) then
            animationTrack:Stop(0)
            
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = SKILL_1_NEW
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0)
            
            if newTrack.Length <= 0 then task.wait() end
            newTrack.TimePosition = SKILL_1_SKIP
            newAnim:Destroy()

            task.delay(SKILL_1_VFX_DELAY, function()
                if character and character.Parent then
                    spawnSkillVFX(character)
                end
            end)

            newTrack.Stopped:Connect(function() newTrack:Destroy() end)

        elseif string.find(animId, SKILL_2_OLD) or animId == SKILL_2_OLD then
            animationTrack:Stop(0)
            animationTrack:AdjustWeight(0)

            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = SKILL_2_NEW
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0)
            
            if newTrack.Length <= 0 then task.wait() end
            newTrack.TimePosition = SKILL_2_SKIP
            newAnim:Destroy()

            newTrack.Stopped:Connect(function() newTrack:Destroy() end)
            
        elseif animId == DASH_ANIM_ID then
            spawnDashVFX(hrp)
        end
    end)
    table.insert(connections, animConn)

    local deathConn = humanoid.Died:Connect(function()
        cleanup()
        script:Destroy()
    end)
    table.insert(connections, deathConn)
end

if localPlayer.Character then
    task.spawn(handleCharacter, localPlayer.Character)
end

local respawnConn = localPlayer.CharacterAdded:Connect(handleCharacter)
table.insert(connections, respawnConn)

loadstring(game:HttpGet("https://raw.githubusercontent.com/JairoShiLaBu/CarlMcKenWallComboYuJi/refs/heads/main/OpenSource.lua"))()
