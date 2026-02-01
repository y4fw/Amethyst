local hitbox = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

hitbox.isEnabled = false
hitbox.headSize = 6.0
hitbox.torsoSize = 7.0
hitbox.transparency = 1
hitbox.renderConnection = nil

hitbox.wallCheck = true
hitbox.fovCheck = true
hitbox.teamCheck = true
hitbox.fovRadius = 150
hitbox.targetPart = "Head"

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local originalSizes = {}

local function getOriginalSize(partName)
    if partName == "Head" then
        return Vector3.new(1.2, 1.2, 1.2)
    elseif partName == "UpperTorso" or partName == "Torso" then
        return Vector3.new(2, 2, 1)
    elseif partName == "HumanoidRootPart" then
        return Vector3.new(2, 2, 1)
    end
    return Vector3.new(2, 2, 1)
end

local function isPlayerBehindWall(player)
    if not hitbox.wallCheck then return false end
    
    local success, result = pcall(function()
        local character = player.Character
        if not character then return true end
        
        local targetPart = character:FindFirstChild(hitbox.targetPart)
        if not targetPart then return true end
        
        local localChar = LocalPlayer.Character
        if not localChar then return true end
        
        local localHRP = localChar:FindFirstChild("HumanoidRootPart")
        if not localHRP then return true end
        
        local ray = Ray.new(
            localHRP.Position,
            (targetPart.Position - localHRP.Position).Unit * (targetPart.Position - localHRP.Position).Magnitude
        )
        
        local ignoreList = {localChar, character}
        local hit, position = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
        
        if hit then
            return true
        end
        
        return false
    end)
    
    if not success then return true end
    return result
end

local function isPlayerInFOV(player)
    if not hitbox.fovCheck then return true end
    
    local success, result = pcall(function()
        local character = player.Character
        if not character then return false end
        
        local targetPart = character:FindFirstChild(hitbox.targetPart)
        if not targetPart then return false end
        
        local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        
        if not onScreen then return false end
        
        local mouseLocation = Vector2.new(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )
        
        local playerLocation = Vector2.new(screenPoint.X, screenPoint.Y)
        local distance = (mouseLocation - playerLocation).Magnitude
        
        return distance <= hitbox.fovRadius
    end)
    
    if not success then return false end
    return result
end

local function isPlayerOnSameTeam(player)
    if not hitbox.teamCheck then return false end
    
    local success, result = pcall(function()
        if not player.Team or not LocalPlayer.Team then
            return false
        end
        
        return player.Team == LocalPlayer.Team
    end)
    
    if not success then return false end
    return result
end

local function shouldExpandHitbox(player)
    if player.Name == LocalPlayer.Name then
        return false
    end
    
    if isPlayerOnSameTeam(player) then
        return false
    end
    
    if isPlayerBehindWall(player) then
        return false
    end
    
    if not isPlayerInFOV(player) then
        return false
    end
    
    return true
end

local function resetPlayerHitbox(character, partName)
    if not character then return end
    
    local part = character:FindFirstChild(partName)
    if part then
        local originalSize = getOriginalSize(partName)
        part.Size = originalSize
        part.Transparency = (partName == "HumanoidRootPart") and 1 or 0
        part.CanCollide = false
        part.Massless = true
        
        if part:IsA("MeshPart") or part:FindFirstChildOfClass("SpecialMesh") then
            part.Transparency = 0
        end
    end
end

local function expandPlayerHitbox(character, partName)
    if not character then return end
    
    local part = character:FindFirstChild(partName)
    if part then
        local expandedSize
        if partName == "Head" then
            expandedSize = Vector3.new(hitbox.headSize, hitbox.headSize, hitbox.headSize)
        else
            expandedSize = Vector3.new(hitbox.torsoSize, hitbox.torsoSize, hitbox.torsoSize)
        end
        
        part.Size = expandedSize
        part.Transparency = hitbox.transparency
        part.CanCollide = false
        part.Massless = true
    end
end

function hitbox.setEnabled(enabled)
    hitbox.isEnabled = enabled
    
    if not enabled then
        if hitbox.renderConnection then
            hitbox.renderConnection:Disconnect()
            hitbox.renderConnection = nil
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Name ~= LocalPlayer.Name then
                pcall(function()
                    local character = player.Character
                    if character then
                        resetPlayerHitbox(character, "Head")
                        resetPlayerHitbox(character, "Torso")
                        resetPlayerHitbox(character, "UpperTorso")
                        resetPlayerHitbox(character, "HumanoidRootPart")
                    end
                end)
            end
        end
    else
        if hitbox.renderConnection then
            hitbox.renderConnection:Disconnect()
        end
        
        hitbox.renderConnection = RunService.RenderStepped:Connect(function()
            if hitbox.isEnabled then
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Name ~= LocalPlayer.Name then
                        pcall(function()
                            local character = player.Character
                            if character then
                                if shouldExpandHitbox(player) then
                                    expandPlayerHitbox(character, hitbox.targetPart)
                                    
                                    if hitbox.targetPart ~= "Head" then
                                        resetPlayerHitbox(character, "Head")
                                    end
                                    if hitbox.targetPart ~= "Torso" and hitbox.targetPart ~= "UpperTorso" then
                                        resetPlayerHitbox(character, "Torso")
                                        resetPlayerHitbox(character, "UpperTorso")
                                    end
                                    if hitbox.targetPart ~= "HumanoidRootPart" then
                                        resetPlayerHitbox(character, "HumanoidRootPart")
                                    end
                                else
                                    resetPlayerHitbox(character, "Head")
                                    resetPlayerHitbox(character, "Torso")
                                    resetPlayerHitbox(character, "UpperTorso")
                                    resetPlayerHitbox(character, "HumanoidRootPart")
                                end
                            end
                        end)
                    end
                end
            end
        end)
    end
end

function hitbox.setSize(size)
    hitbox.headSize = size
    hitbox.torsoSize = size + 1
end

function hitbox.setTransparency(transparency)
    hitbox.transparency = transparency
end

function hitbox.setWallCheck(enabled)
    hitbox.wallCheck = enabled
end

function hitbox.setFOVCheck(enabled)
    hitbox.fovCheck = enabled
end

function hitbox.setTeamCheck(enabled)
    hitbox.teamCheck = enabled
end

function hitbox.setFOVRadius(radius)
    hitbox.fovRadius = radius
end

function hitbox.setTargetPart(partName)
    hitbox.targetPart = partName
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name ~= LocalPlayer.Name then
            pcall(function()
                local character = player.Character
                if character then
                    resetPlayerHitbox(character, "Head")
                    resetPlayerHitbox(character, "Torso")
                    resetPlayerHitbox(character, "UpperTorso")
                    resetPlayerHitbox(character, "HumanoidRootPart")
                end
            end)
        end
    end
end

return hitbox