local autoclicker = {}

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

autoclicker.isEnabled = false
autoclicker.clickDelay = 0.1
autoclicker.isAdvancedMode = false
autoclicker.targetClicks = 400
autoclicker.targetTime = 420
autoclicker.currentClicks = 0
autoclicker.startTime = 0
autoclicker.connections = {}

local function findMinigameScreen()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local screen = gui:FindFirstChild("Screen")
            if screen and screen:IsA("Frame") then
                return screen
            end
        end
    end
    
    return nil
end

local function simulateInput(inputButton, keyRequired)
    if not autoclicker.isEnabled then return end
    
    task.wait(autoclicker.clickDelay)
    
    if not inputButton or not inputButton.Parent then return end
    if inputButton:GetAttribute("Completed") then return end
    
    if keyRequired and keyRequired ~= "TAP" then
        local keyCode = Enum.KeyCode[keyRequired]
        
        if keyCode then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            
            autoclicker.currentClicks = autoclicker.currentClicks + 1
        end
    else
        if inputButton:IsA("ImageButton") then
            local success = pcall(function()
                for _, connection in pairs(getconnections(inputButton.MouseButton1Down)) do
                    connection:Fire()
                end
            end)
            
            if not success then
                local pos = inputButton.AbsolutePosition + (inputButton.AbsoluteSize / 2)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
            end
            
            autoclicker.currentClicks = autoclicker.currentClicks + 1
        end
    end
end

function autoclicker.setEnabled(enabled, notifyFunc)
    autoclicker.isEnabled = enabled
    
    if enabled then
        autoclicker.currentClicks = 0
        autoclicker.startTime = os.clock()
        
        if autoclicker.isAdvancedMode then
            local calculatedDelay = autoclicker.targetTime / autoclicker.targetClicks
            autoclicker.clickDelay = calculatedDelay
        end
        
        local screen = findMinigameScreen()
        
        if not screen then
            if notifyFunc then
                notifyFunc("Erro", "Minigame não encontrado", 2)
            end
            autoclicker.isEnabled = false
            return false
        end
        
        autoclicker.cleanup()
        
        table.insert(autoclicker.connections, screen.ChildAdded:Connect(function(child)
            if not autoclicker.isEnabled then return end
            
            if child:IsA("ImageButton") and child.Name == "InputTemplate" then
                task.wait(0.05)
                
                local textLabel = child:FindFirstChildWhichIsA("TextLabel")
                local keyRequired = textLabel and textLabel.Text or "TAP"
                
                task.spawn(function()
                    simulateInput(child, keyRequired)
                end)
            end
        end))
        
        if notifyFunc then
            notifyFunc("Auto JJS", "Ativado com sucesso", 2)
        end
        
        return true
    else
        autoclicker.cleanup()
        
        if notifyFunc then
            local elapsed = os.clock() - autoclicker.startTime
            notifyFunc("Auto JJS", string.format("Desativado - %d cliques em %.1fs", autoclicker.currentClicks, elapsed), 3)
        end
        
        return true
    end
end

function autoclicker.setDelay(delay)
    autoclicker.clickDelay = delay
end

function autoclicker.setAdvancedMode(enabled)
    autoclicker.isAdvancedMode = enabled
end

function autoclicker.setTargetClicks(clicks)
    autoclicker.targetClicks = clicks
end

function autoclicker.setTargetTime(time)
    autoclicker.targetTime = time
end

function autoclicker.getProgress()
    local elapsed = os.clock() - autoclicker.startTime
    return autoclicker.currentClicks, autoclicker.targetClicks, elapsed
end

function autoclicker.cleanup()
    for _, connection in pairs(autoclicker.connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    autoclicker.connections = {}
end

return autoclicker