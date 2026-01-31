local aimbot = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

aimbot.isEnabled = false
aimbot.targetPart = "Head"
aimbot.fov = 100
aimbot.wallCheck = true
aimbot.teamCheck = true
aimbot.smoothness = 0.5
aimbot.isAiming = false

local connection = nil

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = aimbot.fov
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                if not (aimbot.teamCheck and player.Team == LocalPlayer.Team) then
                    local targetPart = character:FindFirstChild(aimbot.targetPart) or character:FindFirstChild("HumanoidRootPart")
                    
                    if targetPart then
                        local screenPosition, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                        
                        if onScreen then
                            local mousePos = UserInputService:GetMouseLocation()
                            local screenPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
                            local distance = (mousePos - screenPos2D).Magnitude
                            
                            if distance < shortestDistance then
                                if aimbot.wallCheck then
                                    local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * (targetPart.Position - Camera.CFrame.Position).Magnitude)
                                    local part, position = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, character})
                                    
                                    if not part then
                                        closestPlayer = targetPart
                                        shortestDistance = distance
                                    end
                                else
                                    closestPlayer = targetPart
                                    shortestDistance = distance
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function aimAt(targetPart)
    if not targetPart then return end
    
    local targetPosition = targetPart.Position
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position, targetPosition)
    
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, aimbot.smoothness)
end

function aimbot.toggleAiming()
    aimbot.isAiming = not aimbot.isAiming
end

function aimbot.setEnabled(enabled)
    aimbot.isEnabled = enabled
    
    if enabled then
        if connection then connection:Disconnect() end
        
        connection = RunService.RenderStepped:Connect(function()
            if aimbot.isEnabled and aimbot.isAiming then
                local target = getClosestPlayerInFOV()
                if target then
                    aimAt(target)
                end
            end
        end)
    else
        if connection then
            connection:Disconnect()
            connection = nil
        end
        aimbot.isAiming = false
    end
end

function aimbot.setTargetPart(part)
    aimbot.targetPart = part
end

function aimbot.setFOV(fov)
    aimbot.fov = fov
end

function aimbot.setWallCheck(enabled)
    aimbot.wallCheck = enabled
end

function aimbot.setTeamCheck(enabled)
    aimbot.teamCheck = enabled
end

function aimbot.setSmoothness(value)
    aimbot.smoothness = value
end

return aimbot