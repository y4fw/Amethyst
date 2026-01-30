local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local baseURL = "https://raw.githubusercontent.com/y4fw/Amethyst/main/"

local function loadModule(name)
    local url = baseURL .. name
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        return nil
    end
    
    if result == "" or result:match("404") then
        return nil
    end
    
    local compiled, compileError = loadstring(result)
    
    if not compiled then
        return nil
    end
    
    local executed, module = pcall(compiled)
    
    if not executed then
        return nil
    end
    
    if module == nil then
        return nil
    end
    
    return module
end

local recording = loadModule("core/recording.lua")
if not recording then error("[+] Falha ao carregar core/recording.lua") end

local playback = loadModule("core/playback.lua")
if not playback then error("[+] Falha ao carregar core/playback.lua") end

local storage = loadModule("core/storage.lua")
if not storage then error("[+] Falha ao carregar core/storage.lua") end

local marker = loadModule("utils/marker.lua")
if not marker then error("[+] Falha ao carregar utils/marker.lua") end

local interpolation = loadModule("utils/interpolation.lua")
if not interpolation then error("[+] Falha ao carregar utils/interpolation.lua") end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local loadedTASData = nil
local isRecordingModeEnabled = false
local isPlaybackModeEnabled = false
local selectedTASFileName = ""

storage.initialize()

local Window = Fluent:CreateWindow({
    Title = "Amethyst",
    SubTitle = "by y4fw",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K
})

local Tabs = {
    Record = Window:AddTab({ Title = "Gravar TAS", Icon = "circle-dot" }),
    Playback = Window:AddTab({ Title = "Reproduzir TAS", Icon = "play" }),
    Settings = Window:AddTab({ Title = "Configurações", Icon = "settings" })
}

local Options = Fluent.Options

local function notify(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration
    })
end

Tabs.Record:AddParagraph({
    Title = "Controles",
    Content = "Ative o modo de gravação, depois use E para iniciar e Q para parar."
})

local RecordModeToggle = Tabs.Record:AddToggle("RecordMode", {
    Title = "Ativar Modo de Gravação",
    Default = false
})

RecordModeToggle:OnChanged(function()
    isRecordingModeEnabled = Options.RecordMode.Value
    if isRecordingModeEnabled then
        notify("Gravando!", "Pressione E para iniciar, Q para parar", 3)
    else
        if recording.isRecording then
            recording.endRecording(notify)
        end
    end
end)

local FrameCounterLabel = Tabs.Record:AddParagraph({
    Title = "Status",
    Content = "Frames Gravados: 0"
})

local SaveFileNameInput = Tabs.Record:AddInput("SaveFileName", {
    Title = "Nome do Arquivo",
    Default = "",
    Placeholder = "Digite o nome...",
    Numeric = false,
    Finished = false,
    Callback = function(value) end
})

Tabs.Record:AddButton({
    Title = "Salvar TAS",
    Description = "Salvar gravação atual",
    Callback = function()
        local fileName = Options.SaveFileName.Value
        storage.saveTASToFile(fileName, recording.recordedFrames, notify)
    end
})

Tabs.Playback:AddParagraph({
    Title = "Carregar TAS",
    Content = "Selecione um TAS salvo da lista abaixo para carregar."
})

local TASFileDropdown = Tabs.Playback:AddDropdown("TASFileSelect", {
    Title = "Selecionar TAS",
    Values = storage.getTASFileList(),
    Multi = false,
    Default = 1
})

TASFileDropdown:OnChanged(function(value)
    if value then
        local tasData = storage.loadTASFromFile(value, notify)
        if tasData then
            loadedTASData = tasData
            selectedTASFileName = value
        end
    end
end)

Tabs.Playback:AddButton({
    Title = "Atualizar Lista",
    Description = "Atualizar lista de TAS salvos",
    Callback = function()
        local updatedList = storage.getTASFileList()
        TASFileDropdown:SetValues(updatedList)
        notify("Lista Atualizada", "Lista de TAS atualizada", 2)
    end
})

Tabs.Playback:AddButton({
    Title = "Deletar TAS",
    Description = "Deletar TAS selecionado",
    Callback = function()
        if selectedTASFileName ~= "" then
            storage.deleteTASFile(selectedTASFileName, notify)
            selectedTASFileName = ""
            loadedTASData = nil
            local updatedList = storage.getTASFileList()
            TASFileDropdown:SetValues(updatedList)
        else
            notify("Erro", "Nenhum TAS selecionado", 2)
        end
    end
})

Tabs.Playback:AddParagraph({
    Title = "Reproduzir TAS",
    Content = "Ative o modo de reprodução e use E para iniciar, Q para parar."
})

local PlaybackModeToggle = Tabs.Playback:AddToggle("PlaybackMode", {
    Title = "Ativar Modo de Reprodução",
    Default = false
})

PlaybackModeToggle:OnChanged(function()
    isPlaybackModeEnabled = Options.PlaybackMode.Value
    if isPlaybackModeEnabled then
        if not loadedTASData or #loadedTASData == 0 then
            notify("Erro", "Carregue um TAS primeiro", 2)
            Options.PlaybackMode:SetValue(false)
            isPlaybackModeEnabled = false
            return
        end
        
        local firstFrameData = loadedTASData[1]
        if firstFrameData and firstFrameData.cf then
            local startPosition = Vector3.new(firstFrameData.cf[1], firstFrameData.cf[2], firstFrameData.cf[3])
            marker.createStartPositionMarker(startPosition)
            notify("Modo de Reprodução", "Vá até o marcador verde, pressione E para iniciar, Q para parar", 4)
        end
    else
        if playback.isPlaying then
            playback.stopPlayback(HumanoidRootPart, Humanoid, notify, function()
                marker.destroyMarker()
            end)
        end
        marker.destroyMarker()
    end
end)

Tabs.Settings:AddParagraph({
    Title = "Descrição",
    Content = "O melhor SCRIPT para Exércitos Brasileiros do Roblox!"
})

Tabs.Settings:AddParagraph({
    Title = "Créditos",
    Content = "Feito por y4fw"
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("AmethystTAS")
SaveManager:SetFolder("AmethystTAS/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

UserInputService.InputBegan:Connect(function(inputObject, isProcessedByGame)
    if isProcessedByGame then return end
    
    if inputObject.KeyCode == Enum.KeyCode.E then
        if isRecordingModeEnabled and not recording.isRecording then
            recording.beginRecording(HumanoidRootPart, Character, workspace.CurrentCamera, notify)
        elseif isPlaybackModeEnabled and not playback.isPlaying then
            if loadedTASData and #loadedTASData > 0 then
                local firstFrameData = loadedTASData[1]
                if firstFrameData and firstFrameData.cf then
                    local startPosition = Vector3.new(firstFrameData.cf[1], firstFrameData.cf[2], firstFrameData.cf[3])
                    local distanceToMarker = (HumanoidRootPart.Position - startPosition).Magnitude
                    if distanceToMarker <= 12 then
                        marker.destroyMarker()
                        playback.startPlayback(loadedTASData, HumanoidRootPart, Humanoid, workspace.CurrentCamera, notify, function()
                            marker.destroyMarker()
                        end, interpolation)
                    else
                        notify("Erro", "Você deve estar no marcador verde", 2)
                    end
                end
            end
        end
    elseif inputObject.KeyCode == Enum.KeyCode.Q then
        if isRecordingModeEnabled and recording.isRecording then
            recording.endRecording(notify)
        elseif isPlaybackModeEnabled and playback.isPlaying then
            playback.stopPlayback(HumanoidRootPart, Humanoid, notify, function()
                marker.destroyMarker()
            end)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if recording.isRecording then
        local recordDuration = recording.getDuration()
        FrameCounterLabel:SetDesc(string.format("Frames Gravados: %d (%.2fs)", recording.getFrameCount(), recordDuration))
    end
end)

Fluent:Notify({
    Title = "Amethyst",
    Content = "Carregado com sucesso",
    Duration = 3
})

SaveManager:LoadAutoloadConfig()