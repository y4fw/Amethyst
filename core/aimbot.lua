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
local lockedTarget = nil

-- FOV circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Radius = aimbot.fov
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.NumSides = 64

RunService.RenderStepped:Connect(function()
    if aimbot.isEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = aimbot.fov
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

local function isTargetValid(targetPart)
    if not targetPart or not targetPart.Parent then return false end

    local character = targetPart.Parent
    local player = Players:GetPlayerFromCharacter(character)

    if not player or player == LocalPlayer then return false end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    if aimbot.teamCheck and player.Team == LocalPlayer.Team then return false end

    local screenPosition, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
    if not onScreen then return false end

    if aimbot.wallCheck then
        local origin = Camera.CFrame.Position
        local direction = targetPart.Position - origin
        local ray = Ray.new(origin, direction.Unit * direction.Magnitude)
        local part = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, character})
        if part then return false end
    end

    return true
end

-- Pega o player que está sob o mouse no momento de apertar E
local function getTargetUnderMouse()
    local closestPart = nil
    local shortestDistance = aimbot.fov

    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                if not (aimbot.teamCheck and player.Team == LocalPlayer.Team) then
                    local targetPart = character:FindFirstChild(aimbot.targetPart) or character:FindFirstChild("HumanoidRootPart")

                    if targetPart then
                        local screenPosition, onScreen = Camera:WorldToScreenPoint(targetPart.Position)

                        if onScreen then
                            local screenPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
                            local distance = (mousePos - screenPos2D).Magnitude

                            if distance < shortestDistance then
                                if aimbot.wallCheck then
                                    local origin = Camera.CFrame.Position
                                    local direction = targetPart.Position - origin
                                    local ray = Ray.new(origin, direction.Unit * direction.Magnitude)
                                    local part = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, character})
                                    if not part then
                                        closestPart = targetPart
                                        shortestDistance = distance
                                    end
                                else
                                    closestPart = targetPart
                                    shortestDistance = distance
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPart
end

local function aimAt(targetPart)
    if not targetPart then return end

    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position, targetPart.Position)
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, aimbot.smoothness)
end

function aimbot.toggleAiming()
    if aimbot.isAiming then
        -- Desativa e destravar alvo
        aimbot.isAiming = false
        lockedTarget = nil
    else
        -- Trava no player que está sob o mouse agora
        local target = getTargetUnderMouse()
        if target then
            lockedTarget = target
            aimbot.isAiming = true
        end
        -- Se não tiver ninguém no FOV, não ativa
    end
end

function aimbot.setEnabled(enabled)
    aimbot.isEnabled = enabled

    if enabled then
        if connection then connection:Disconnect() end

        connection = RunService.RenderStepped:Connect(function()
            if not aimbot.isEnabled or not aimbot.isAiming then return end

            if lockedTarget and not isTargetValid(lockedTarget) then
                lockedTarget = nil
                aimbot.isAiming = false
            end

            if lockedTarget then
                aimAt(lockedTarget)
            end
        end)
    else
        if connection then
            connection:Disconnect()
            connection = nil
        end
        aimbot.isAiming = false
        lockedTarget = nil
    end
end

function aimbot.setTargetPart(part)
    aimbot.targetPart = part
    lockedTarget = nil
end

function aimbot.setFOV(fov)
    aimbot.fov = fov
    fovCircle.Radius = fov
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