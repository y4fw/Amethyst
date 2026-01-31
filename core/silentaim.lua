local silentaim = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

silentaim.isEnabled = false
silentaim.targetPart = "Head"
silentaim.fov = 100
silentaim.wallCheck = true
silentaim.teamCheck = true
silentaim.visibleCheck = true

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = silentaim.fov
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                if silentaim.teamCheck and player.Team == LocalPlayer.Team then
                    continue
                end
                
                local targetPart = character:FindFirstChild(silentaim.targetPart) or character:FindFirstChild("HumanoidRootPart")
                
                if targetPart then
                    local screenPosition, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                    
                    if onScreen then
                        local mousePosition = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local screenPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
                        local distance = (mousePosition - screenPos2D).Magnitude
                        
                        if distance < shortestDistance then
                            if silentaim.wallCheck then
                                local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * (targetPart.Position - Camera.CFrame.Position).Magnitude)
                                local part, position = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, character})
                                
                                if not part then
                                    closestPlayer = player
                                    shortestDistance = distance
                                end
                            else
                                closestPlayer = player
                                shortestDistance = distance
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

function silentaim.getTarget()
    if not silentaim.isEnabled then
        return nil
    end
    
    local target = getClosestPlayerInFOV()
    
    if target and target.Character then
        local targetPart = target.Character:FindFirstChild(silentaim.targetPart) or target.Character:FindFirstChild("HumanoidRootPart")
        return targetPart
    end
    
    return nil
end

function silentaim.setEnabled(enabled)
    silentaim.isEnabled = enabled
end

function silentaim.setTargetPart(part)
    silentaim.targetPart = part
end

function silentaim.setFOV(fov)
    silentaim.fov = fov
end

function silentaim.setWallCheck(enabled)
    silentaim.wallCheck = enabled
end

function silentaim.setTeamCheck(enabled)
    silentaim.teamCheck = enabled
end

function silentaim.setVisibleCheck(enabled)
    silentaim.visibleCheck = enabled
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if silentaim.isEnabled and method == "FireServer" or method == "InvokeServer" then
        if self.Name == "ShootEvent" or self.Name == "DamageEvent" or self.Name == "HitEvent" then
            local target = silentaim.getTarget()
            
            if target then
                args[1] = target.Position
                return oldNamecall(self, unpack(args))
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

return silentaim
