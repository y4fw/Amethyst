local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local baseURL = "https://raw.githubusercontent.com/y4fw/Amethyst/main/"

print("=== Carregando Amethyst TAS ===")

local function loadModule(name)
    print("Carregando " .. name .. "...")
    local url = baseURL .. name
    print("URL: " .. url)
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("ERRO ao baixar " .. name .. ": " .. tostring(result))
        return nil
    end
    
    if result == "" or result:match("404") then
        warn("ERRO: Arquivo " .. name .. " não encontrado no GitHub!")
        warn("Verifique se o arquivo existe em: " .. url)
        return nil
    end
    
    print("Arquivo baixado, compilando...")
    local compiled, compileError = loadstring(result)
    
    if not compiled then
        warn("ERRO ao compilar " .. name .. ": " .. tostring(compileError))
        return nil
    end
    
    print("Executando módulo...")
    local executed, module = pcall(compiled)
    
    if not executed then
        warn("ERRO ao executar " .. name .. ": " .. tostring(module))
        return nil
    end
    
    if module == nil then
        warn("ERRO: " .. name .. " retornou nil!")
        return nil
    end
    
    print("✓ " .. name .. " carregado com sucesso!")
    return module
end

local recording = loadModule("core/recording.lua")
if not recording then error("Falha ao carregar recording.lua") end

local playback = loadModule("core/playback.lua")
if not playback then error("Falha ao carregar playback.lua") end

local storage = loadModule("core/storage.lua")
if not storage then error("Falha ao carregar storage.lua") end

local marker = loadModule("utils/marker.lua")
if not marker then error("Falha ao carregar marker.lua") end

local interpolation = loadModule("utils/interpolation.lua")
if not interpolation then error("Falha ao carregar interpolation.lua") end

print("=== Todos os módulos carregados! ===")
print("")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local loadedTASData = nil
local recordingModeEnabled = false
local playbackModeEnabled = false
local selectedTASFileName = ""

storage.initialize()

local Window = Rayfield:CreateWindow({
    Name = "Amethyst",
    Icon = 0,
    LoadingTitle = "Amethyst",
    LoadingSubtitle = "Sistema TAS",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false
})

local RecordTab = Window:CreateTab("Gravar TAS")
local PlaybackTab = Window:CreateTab("Reproduzir TAS")
local SettingsTab = Window:CreateTab("Configurações")

local function notify(title, content, duration)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration,
        Image = 117542291098497
    })
end

RecordTab:CreateParagraph({
    Title = "Controles de Gravação",
    Content = "Ative o modo de gravação, depois use E para iniciar e Q para parar."
})

local RecordModeToggle = RecordTab:CreateToggle({
    Name = "Ativar Modo de Gravação",
    CurrentValue = false,
    Flag = "ModoGravacao",
    Callback = function(toggleValue)
        recordingModeEnabled = toggleValue
        if toggleValue then
            notify("Modo de Gravação", "Pressione E para iniciar, Q para parar", 3)
        else
            if recording.isRecording then
                recording.endRecording(notify)
            end
        end
    end
})

local FrameCounterLabel = RecordTab:CreateLabel("Frames Gravados: 0")

local SaveFileNameInput = RecordTab:CreateInput({
    Name = "Nome do TAS",
    CurrentValue = "",
    PlaceholderText = "Digite o nome...",
    RemoveTextAfterFocusLost = false,
    Flag = "SaveName",
    Callback = function(inputText) end
})

RecordTab:CreateButton({
    Name = "Salvar TAS",
    Callback = function()
        local fileName = SaveFileNameInput.CurrentValue
        storage.saveTASToFile(fileName, recording.recordedFrames, notify)
    end
})

PlaybackTab:CreateParagraph({
    Title = "Carregar TAS Salvo",
    Content = "Selecione um TAS salvo da lista abaixo para carregar."
})

local TASFileDropdown = PlaybackTab:CreateDropdown({
    Name = "Selecionar TAS",
    Options = storage.getTASFileList(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "TASDropdown",
    Callback = function(selectedOptions)
        if selectedOptions and selectedOptions[1] then
            local tasData = storage.loadTASFromFile(selectedOptions[1], notify)
            if tasData then
                loadedTASData = tasData
                selectedTASFileName = selectedOptions[1]
            end
        end
    end,
})

PlaybackTab:CreateButton({
    Name = "Atualizar Lista",
    Callback = function()
        local updatedList = storage.getTASFileList()
        TASFileDropdown:Refresh(updatedList)
        notify("Lista Atualizada", "Lista de TAS atualizada", 2)
    end
})

PlaybackTab:CreateButton({
    Name = "Deletar TAS Selecionado",
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

PlaybackTab:CreateParagraph({
    Title = "Reproduzir TAS",
    Content = "Ative o modo de reprodução e use E para iniciar, Q para parar."
})

local PlaybackModeToggle = PlaybackTab:CreateToggle({
    Name = "Ativar Modo de Reprodução",
    CurrentValue = false,
    Flag = "ModoReproducao",
    Callback = function(toggleValue)
        playbackModeEnabled = toggleValue
        if toggleValue then
            if not loadedTASData or #loadedTASData == 0 then
                notify("Erro", "Carregue um TAS primeiro", 2)
                PlaybackModeToggle:Set(false)
                playbackModeEnabled = false
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

SettingsTab:CreateParagraph({
    Title = "Controles",
    Content = "Modo de Gravação: E = Iniciar | Q = Parar\nModo de Reprodução: E = Iniciar | Q = Parar"
})

SettingsTab:CreateParagraph({
    Title = "Sistema de Sincronização",
    Content = "Este TAS usa timestamps para garantir que rode na velocidade correta independente do FPS"
})

SettingsTab:CreateLabel("feito por y4fw")

UserInputService.InputBegan:Connect(function(inputObject, isProcessedByGame)
    if isProcessedByGame then return end
    
    if inputObject.KeyCode == Enum.KeyCode.E then
        if recordingModeEnabled and not recording.isRecording then
            recording.beginRecording(HumanoidRootPart, Character, workspace.CurrentCamera, notify)
        elseif playbackModeEnabled and not playback.isPlaying then
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
        if recordingModeEnabled and recording.isRecording then
            recording.endRecording(notify)
        elseif playbackModeEnabled and playback.isPlaying then
            playback.stopPlayback(HumanoidRootPart, Humanoid, notify, function()
                marker.destroyMarker()
            end)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if recording.isRecording then
        local recordDuration = recording.getDuration()
        FrameCounterLabel:Set(string.format("Frames Gravados: %d (%.2fs)", recording.getFrameCount(), recordDuration))
    end
end)

notify("Amethyst", "Carregado com sucesso", 3)
