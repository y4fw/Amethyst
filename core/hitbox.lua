local hitbox = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

hitbox.isEnabled = false
hitbox.headSize = 12
hitbox.transparency = 0.99
hitbox.renderConnection = nil

function hitbox.setEnabled(enabled)
    hitbox.isEnabled = enabled
    
    if not enabled then
        if hitbox.renderConnection then
            hitbox.renderConnection:Disconnect()
            hitbox.renderConnection = nil
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Name ~= Players.LocalPlayer.Name then
                pcall(function()
                    player.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                    player.Character.HumanoidRootPart.Transparency = 1
                    player.Character.HumanoidRootPart.CanCollide = false
                    player.Character.HumanoidRootPart.Material = Enum.Material.Plastic
                    player.Character.HumanoidRootPart.BrickColor = BrickColor.new("Medium stone grey")
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
                    if player.Name ~= Players.LocalPlayer.Name then
                        pcall(function()
                            player.Character.HumanoidRootPart.Size = Vector3.new(hitbox.headSize, hitbox.headSize, hitbox.headSize)
                            player.Character.HumanoidRootPart.Transparency = hitbox.transparency
                            player.Character.HumanoidRootPart.BrickColor = BrickColor.new("Really red")
                            player.Character.HumanoidRootPart.Material = Enum.Material.Neon
                            player.Character.HumanoidRootPart.CanCollide = false
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

return hitbox