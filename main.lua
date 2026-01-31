local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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

local hitbox = loadModule("core/hitbox.lua")
if not hitbox then error("[+] Falha ao carregar core/hitbox.lua") end

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
local version = "1.5.6"

storage.initialize()

local Window = WindUI:CreateWindow({
    Title = "Amethyst",
    Icon = "lucide:sparkles",
    Author = "by y4fw",
    Folder = "AmethystTAS",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark",
    Transparent = true,
    SideBarWidth = 200,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("User icon clicked")
        end,
    },
    KeySystem = {
        Key = { "amethyst" },
        Note = "Digite a key para acessar o Amethyst",
        SaveKey = true,
    },
})

Window:SetToggleKey(Enum.KeyCode.K)

Window:Tag({
    Title = "v" .. version,
    Icon = "lucide:rocket",
    Color = Color3.fromHex("#fccd4a"),
    Radius = 12,
})

local FPSTag = Window:Tag({
    Title = "0 FPS",
    Icon = "lucide:gauge",
    Color = Color3.fromHex("#00ff00"),
    Radius = 12,
})

local PingTag = Window:Tag({
    Title = "0 ms",
    Icon = "lucide:wifi",
    Color = Color3.fromHex("#ff9500"),
    Radius = 12,
})

RunService.Heartbeat:Connect(function()
    local fps = math.floor(1 / RunService.Heartbeat:Wait())
    FPSTag:Set(fps .. " FPS")
end)

task.spawn(function()
    while task.wait(1) do
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        PingTag:Set(ping .. " ms")
    end
end)

local TASSection = Window:Section({
    Title = "Parkours",
})

local RecordTab = TASSection:Tab({
    Title = "Gravar TAS",
    Icon = "lucide:circle-dot"
})

local PlaybackTab = TASSection:Tab({
    Title = "Reproduzir TAS",
    Icon = "lucide:play"
})

local CombatSection = Window:Section({
    Title = "PvP",
})

local HitboxTab = CombatSection:Tab({
    Title = "Hitbox Expander",
    Icon = "lucide:box"
})

local SettingsSection = Window:Section({
    Title = "Configurações",
})

local SettingsTab = SettingsSection:Tab({
    Title = "Configurações",
    Icon = "lucide:settings"
})

local function notify(title, content, duration)
    WindUI:Notify({
        Title = title,
        Content = content,
        Duration = duration,
        Icon = "lucide:info"
    })
end

RecordTab:Section({
    Title = "Controles",
    Desc = "Ative o modo de gravação, depois use E para iniciar e Q para parar.",
    TextSize = 14,
})

local RecordModeToggle = RecordTab:Toggle({
    Title = "Ativar Modo de Gravação",
    Desc = "Habilitar gravação de TAS",
    Value = false,
    Callback = function(state)
        isRecordingModeEnabled = state
        if isRecordingModeEnabled then
            notify("Gravando!", "Pressione E para iniciar, Q para parar", 3)
        else
            if recording.isRecording then
                recording.endRecording(notify)
            end
        end
    end
})

RecordTab:Space()

local FrameCounterParagraph = RecordTab:Paragraph({
    Title = "Status",
    Desc = "Frames Gravados: 0"
})

RecordTab:Space()

local SaveFileNameInput = RecordTab:Input({
    Title = "Nome do Arquivo",
    Desc = "Digite o nome para salvar o TAS",
    Value = "",
    Placeholder = "Digite o nome...",
    Callback = function(value) end
})

RecordTab:Space()

RecordTab:Button({
    Title = "Salvar TAS",
    Desc = "Salvar gravação atual",
    Icon = "lucide:save",
    Callback = function()
        storage.saveTASToFile(SaveFileNameInput.Value, recording.recordedFrames, notify)
    end
})

PlaybackTab:Section({
    Title = "Carregar TAS",
    Desc = "Selecione um TAS salvo da lista abaixo para carregar.",
    TextSize = 14,
})

local TASFileDropdown = PlaybackTab:Dropdown({
    Title = "Selecionar TAS",
    Desc = "Escolha um TAS para reproduzir",
    Values = storage.getTASFileList(),
    Value = nil,
    Multi = false,
    AllowNone = true,
    Callback = function(selectedValue)
        if selectedValue and selectedValue ~= "" then
            local tasData = storage.loadTASFromFile(selectedValue, notify)
            if tasData then
                loadedTASData = tasData
                selectedTASFileName = selectedValue
            end
        end
    end
})

PlaybackTab:Space()

PlaybackTab:Button({
    Title = "Atualizar Lista",
    Desc = "Atualizar lista de TAS salvos",
    Icon = "lucide:refresh-cw",
    Callback = function()
        local updatedList = storage.getTASFileList()
        TASFileDropdown:Refresh(updatedList)
        notify("Lista Atualizada", "Lista de TAS atualizada", 2)
    end
})

PlaybackTab:Space()

PlaybackTab:Button({
    Title = "Deletar TAS",
    Desc = "Deletar TAS selecionado",
    Icon = "lucide:trash",
    Callback = function()
        if selectedTASFileName ~= "" then
            storage.deleteTASFile(selectedTASFileName, notify)
            selectedTASFileName = ""
            loadedTASData = nil
            local updatedList = storage.getTASFileList()
            TASFileDropdown:Refresh(updatedList)
        else
            notify("Erro", "Nenhum TAS selecionado", 2)
        end
    end
})

PlaybackTab:Divider()

PlaybackTab:Section({
    Title = "Reproduzir TAS",
    Desc = "Ative o modo de reprodução e use E para iniciar, Q para parar.",
    TextSize = 14,
})

local PlaybackModeToggle = PlaybackTab:Toggle({
    Title = "Ativar Modo de Reprodução",
    Desc = "Habilitar reprodução de TAS",
    Value = false,
    Callback = function(state)
        isPlaybackModeEnabled = state
        if isPlaybackModeEnabled then
            if not loadedTASData or #loadedTASData == 0 then
                notify("Erro", "Carregue um TAS primeiro", 2)
                PlaybackModeToggle:Set(false)
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
    end
})

HitboxTab:Section({
    Title = "Configurações de Hitbox",
    Desc = "Ajuste o tamanho e transparência da hitbox dos inimigos.",
    TextSize = 14,
})

local HitboxToggle = HitboxTab:Toggle({
    Title = "Ativar Hitbox Expander",
    Desc = "Expandir hitbox dos inimigos",
    Value = false,
    Callback = function(state)
        hitbox.setEnabled(state)
    end
})

HitboxTab:Space()

HitboxTab:Slider({
    Title = "Tamanho da Hitbox",
    Desc = "Ajustar o tamanho da hitbox expandida",
    Step = 0.5,
    Value = {
        Min = 3,
        Max = 15,
        Default = 12,
    },
    Callback = function(value)
        hitbox.setSize(value)
    end
})

HitboxTab:Space()

HitboxTab:Slider({
    Title = "Transparência",
    Desc = "Ajustar a transparência da hitbox (0 = opaco, 1 = invisível)",
    Step = 0.01,
    Value = {
        Min = 0,
        Max = 1,
        Default = 0.99,
    },
    Callback = function(value)
        hitbox.setTransparency(value)
    end
})

SettingsTab:Section({
    Title = "Descrição",
    Desc = "O melhor SCRIPT para Exércitos Brasileiros do Roblox!",
    TextSize = 16,
})

SettingsTab:Space()

SettingsTab:Paragraph({
    Title = "Créditos",
    Desc = "Feito por y4fw"
})

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
        FrameCounterParagraph:SetDesc(string.format("Frames Gravados: %d (%.2fs)", recording.getFrameCount(), recordDuration))
    end
end)

WindUI:Notify({
    Title = "Amethyst",
    Content = "Carregado com sucesso",
    Duration = 3,
    Icon = "lucide:check-circle"
})