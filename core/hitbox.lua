local hitbox = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

hitbox.isEnabled = false
hitbox.headSize = 12
hitbox.transparency = 0.99
hitbox.renderConnection = nil

hitbox.wallCheck = false
hitbox.fovCheck = false
hitbox.teamCheck = true
hitbox.fovRadius = 800

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function isPlayerBehindWall(player)
    if not hitbox.wallCheck then return false end
    
    local success, result = pcall(function()
        local character = player.Character
        if not character then return true end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return true end
        
        local localChar = LocalPlayer.Character
        if not localChar then return true end
        
        local localHRP = localChar:FindFirstChild("HumanoidRootPart")
        if not localHRP then return true end
        
        local direction = (hrp.Position - localHRP.Position)
        local ray = Ray.new(localHRP.Position, direction.Unit * direction.Magnitude)
        
        local ignoreList = {localChar, character}
        
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                if v.Transparency >= 0.9 or not v.CanCollide then
                    table.insert(ignoreList, v)
                end
            end
        end
        
        local hit, position = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
        
        if hit then
            if hit:IsDescendantOf(character) then
                return false
            end
            return true
        end
        
        return false
    end)
    
    if not success then return false end
    return result
end

local function isPlayerInFOV(player)
    if not hitbox.fovCheck then return true end
    
    local success, result = pcall(function()
        local character = player.Character
        if not character then return false end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        local screenPoint, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        
        if not onScreen then return false end
        
        local mouseLocation = Vector2.new(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )
        
        local playerLocation = Vector2.new(screenPoint.X, screenPoint.Y)
        local distance = (mouseLocation - playerLocation).Magnitude
        
        return distance <= hitbox.fovRadius
    end)
    
    if not success then return true end
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
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Size = Vector3.new(2, 2, 1)
                            hrp.Transparency = 1
                            hrp.CanCollide = false
                            hrp.Material = Enum.Material.Plastic
                            hrp.BrickColor = BrickColor.new("Medium stone grey")
                        end
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
                                local hrp = character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    if shouldExpandHitbox(player) then
                                        hrp.Size = Vector3.new(hitbox.headSize, hitbox.headSize, hitbox.headSize)
                                        hrp.Transparency = hitbox.transparency
                                        hrp.BrickColor = BrickColor.new("Really red")
                                        hrp.Material = Enum.Material.ForceField
                                        hrp.CanCollide = false
                                        hrp.Massless = true
                                    else
                                        hrp.Size = Vector3.new(2, 2, 1)
                                        hrp.Transparency = 1
                                        hrp.CanCollide = false
                                        hrp.Material = Enum.Material.Plastic
                                        hrp.BrickColor = BrickColor.new("Medium stone grey")
                                    end
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

return hitbox