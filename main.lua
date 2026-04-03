-- Made by y4fw

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

local playback = loadModule("core/playbackv2.lua")
if not playback then error("[+] Falha ao carregar core/playbackv2.lua") end

local storage = loadModule("core/storage.lua")
if not storage then error("[+] Falha ao carregar core/storage.lua") end

local marker = loadModule("utils/marker.lua")
if not marker then error("[+] Falha ao carregar utils/marker.lua") end

local interpolation = loadModule("utils/interpolation.lua")
if not interpolation then error("[+] Falha ao carregar utils/interpolation.lua") end

local hitbox = loadModule("core/hitbox.lua")
if not hitbox then error("[+] Falha ao carregar core/hitbox.lua") end

local aimbot = loadModule("core/aimbot.lua")
if not aimbot then error("[+] Falha ao carregar core/aimbot.lua") end

local autoclicker = loadModule("core/deltaauto.lua")
if not autoclicker then error("[+] Falha ao carregar core/deltaautojjs.lua") end

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
local version = "1.5.7"

local isPaused = false
local isSafeModeEnabled = false
local isSafeModeAutoWalkEnabled = false
local currentSafeModeKey = "J"

storage.initialize()

local Window = WindUI:CreateWindow({
    Title = "Sapphire.xyz",
    Icon = "lucide:sparkles",
    Author = "by y4fw",
    Folder = "SapphireTAS",
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
        Key = { "sapphire" },
        Note = "Digite a key para acessar o Sapphire",
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

task.spawn(function()
    while task.wait(0.5) do
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        FPSTag:SetTitle(fps .. " FPS")
        
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        PingTag:SetTitle(ping .. " ms")
    end
end)

local TASSection = Window:Section({
    Title = "TAS",
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
    Title = "Combate",
})

local HitboxTab = CombatSection:Tab({
    Title = "Hitbox Expander",
    Icon = "lucide:box"
})

local AimbotTab = CombatSection:Tab({
    Title = "Aimbot",
    Icon = "lucide:target"
})

local EBDoDeltaSection = Window:Section({
    Title = "EB Do Delta",
})

local AutoJJSTab = EBDoDeltaSection:Tab({
    Title = "Auto JJS",
    Icon = "lucide:zap"
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

local function getKeyCodeSafe(keyName)
    if not keyName then return nil end
    local success, keyCode = pcall(function()
        return Enum.KeyCode[keyName]
    end)
    return success and keyCode or nil
end

local function walkToPosition(targetPosition, callback)
    if isWalkingToPosition then return end
    isWalkingToPosition = true
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not isWalkingToPosition or not HumanoidRootPart or not Humanoid then
            connection:Disconnect()
            isWalkingToPosition = false
            if callback then callback() end
            return
        end
        
        local currentPos = HumanoidRootPart.Position
        local distance = (currentPos - targetPosition).Magnitude
        
        if distance < 5 then
            Humanoid:Move(Vector3.new(0, 0, 0))
            connection:Disconnect()
            isWalkingToPosition = false
            if callback then callback() end
            return
        end
        
        local direction = (targetPosition - currentPos).Unit
        local targetCFrame = CFrame.lookAt(currentPos, targetPosition)
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(targetCFrame, 0.1)
        Humanoid:Move(direction)
    end)
end

local function tryStartPlayback()
    if not isPlaybackModeEnabled then
        notify("Erro", "Ative o Modo de Reprodução primeiro", 2)
        return
    end
    if playback.isPlaying then
        notify("Aviso", "Reprodução já está em andamento", 2)
        return
    end
    if not loadedTASData or #loadedTASData == 0 then
        notify("Erro", "Carregue um TAS primeiro", 2)
        return
    end

    local firstFrameData = loadedTASData[1]
    if firstFrameData and firstFrameData.cf then
        local startPosition = Vector3.new(firstFrameData.cf[1], firstFrameData.cf[2], firstFrameData.cf[3])
        local distanceToMarker = (HumanoidRootPart.Position - startPosition).Magnitude
        if distanceToMarker <= 12 then
            marker.destroyMarker()
            isPaused = false
            playback.startPlayback(loadedTASData, HumanoidRootPart, Humanoid, workspace.CurrentCamera, notify, function()
                marker.destroyMarker()
            end, interpolation, isSafeModeEnabled)
        else
            notify("Erro", "Você deve estar no marcador" .. (isSafeModeEnabled and "" or " verde"), 2)
        end
    end
end

local function tryStopPlayback()
    if not playback.isPlaying then
        notify("Aviso", "Nenhuma reprodução em andamento", 2)
        return
    end
    isPaused = false
    playback.stopPlayback(HumanoidRootPart, Humanoid, notify, function()
        marker.destroyMarker()
    end)
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
    Title = "Modo Seguro",
    Desc = "Ativa modo discreto com marker invisível e caminhada humanizada.",
    TextSize = 14,
})

local SafeModeToggle = PlaybackTab:Toggle({
    Title = "Ativar Modo Seguro",
    Desc = "Marker invisível e caminhada humanizada para posição inicial",
    Value = false,
    Callback = function(state)
        isSafeModeEnabled = state
    end
})

PlaybackTab:Space()

local SafeModeAutoWalkToggle = PlaybackTab:Toggle({
    Title = "Auto Caminhar ao Ativar Reprodução",
    Desc = "Caminha automaticamente quando ativa o Modo de Reprodução",
    Value = false,
    Callback = function(state)
        isSafeModeAutoWalkEnabled = state
    end
})

PlaybackTab:Space()

local SafeModeKeybind = PlaybackTab:Keybind({
    Title = "Tecla para Caminhar (Modo Seguro)",
    Desc = "Pressione para caminhar até a posição inicial",
    Value = "J",
    Callback = function(key)
        currentSafeModeKey = key
    end
})

PlaybackTab:Space()

PlaybackTab:Divider()

PlaybackTab:Section({
    Title = "Reproduzir TAS",
    Desc = "Ative o modo de reprodução e use E para iniciar, Q para parar.\nNo mobile, use os botões abaixo.",
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
                marker.createStartPositionMarker(startPosition, isSafeModeEnabled)
                
                if isSafeModeEnabled and isSafeModeAutoWalkEnabled then
                    walkToPosition(startPosition, function()
                        notify("Modo Seguro", "Posição atingida", 2)
                    end)
                    notify("Modo Seguro", "Caminhando para posição inicial...", 3)
                else
                    notify("Modo de Reprodução", "Vá até o marcador" .. (isSafeModeEnabled and "" or " verde") .. ", pressione E para iniciar, Q para parar", 4)
                end
            end
        else
            if playback.isPlaying then
                playback.stopPlayback(HumanoidRootPart, Humanoid, notify, function()
                    marker.destroyMarker()
                end)
            end
            isPaused = false
            marker.destroyMarker()
        end
    end
})

PlaybackTab:Space()

PlaybackTab:Section({
    Title = "Controles Mobile",
    Desc = "Use os botões abaixo para controlar a reprodução sem teclado.",
    TextSize = 14,
})

PlaybackTab:Button({
    Title = "▶  Iniciar Reprodução",
    Desc = "Inicia o TAS (equivale ao E)",
    Icon = "lucide:play",
    Callback = function()
        tryStartPlayback()
    end
})

PlaybackTab:Space()

PlaybackTab:Button({
    Title = "⏸  Pausar / Retomar",
    Desc = "Pausa ou retoma a reprodução",
    Icon = "lucide:pause",
    Callback = function()
        if not playback.isPlaying and not isPaused then
            notify("Aviso", "Nenhuma reprodução em andamento", 2)
            return
        end

        if isPaused then
            if playback.resumePlayback then
                playback.resumePlayback()
                isPaused = false
                notify("Reprodução", "Retomado", 1)
            else
                isPaused = false
                tryStartPlayback()
            end
        else
            if playback.pausePlayback then
                playback.pausePlayback()
                isPaused = true
                notify("Reprodução", "Pausado", 1)
            else
                playback.stopPlayback(HumanoidRootPart, Humanoid, notify, function() end)
                isPaused = true
                notify("Reprodução", "Pausado (parada temporária)", 1)
            end
        end
    end
})

PlaybackTab:Space()

PlaybackTab:Button({
    Title = "⏹  Parar Reprodução",
    Desc = "Para o TAS (equivale ao Q)",
    Icon = "lucide:square",
    Callback = function()
        tryStopPlayback()
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
        Default = 4,
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

HitboxTab:Space()

HitboxTab:Toggle({
    Title = "Verificar Parede",
    Desc = "Não expandir hitbox através de paredes",
    Value = true,
    Callback = function(state)
        hitbox.setWallCheck(state)
    end
})

HitboxTab:Space()

HitboxTab:Toggle({
    Title = "Verificar Campo de Visão",
    Desc = "Só expandir hitbox de jogadores visíveis na tela",
    Value = true,
    Callback = function(state)
        hitbox.setFOVCheck(state)
    end
})

HitboxTab:Space()

HitboxTab:Input({
    Title = "Raio do Campo de Visão",
    Desc = "Distância em pixels do centro da tela",
    Value = "500",
    Placeholder = "500",
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            hitbox.setFOVRadius(num)
        end
    end
})

HitboxTab:Space()

HitboxTab:Toggle({
    Title = "Verificar Time",
    Desc = "Ignorar jogadores do mesmo time",
    Value = true,
    Callback = function(state)
        hitbox.setTeamCheck(state)
    end
})

local currentHitboxKey = "P"

local HitboxKeybind = HitboxTab:Keybind({
    Title = "Tecla de Atalho",
    Desc = "Tecla para ativar/desativar rapidamente",
    Value = "P",
    Callback = function(key)
        currentHitboxKey = key
    end
})

HitboxTab:Space()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local hitboxKey = getKeyCodeSafe(currentHitboxKey)
    if hitboxKey and input.KeyCode == hitboxKey then
        if hitbox.isEnabled then
            local currentState = hitbox.isEnabled
            HitboxToggle:Set(not currentState)
            hitbox.setEnabled(not currentState)
        end
    end
end)

AimbotTab:Section({
    Title = "Configurações Aimbot",
    Desc = "Sistema de mira automática que move a câmera.",
    TextSize = 14,
})

local AimbotToggle = AimbotTab:Toggle({
    Title = "Ativar Aimbot",
    Desc = "Ativar mira automática",
    Value = false,
    Callback = function(state)
        aimbot.setEnabled(state)
    end
})

AimbotTab:Space()

AimbotTab:Dropdown({
    Title = "Parte Alvo",
    Desc = "Parte do corpo para mirar",
    Values = {"Head", "HumanoidRootPart", "Torso"},
    Value = "Head",
    Multi = false,
    AllowNone = false,
    Callback = function(selectedValue)
        if selectedValue then
            aimbot.setTargetPart(selectedValue)
        end
    end
})

AimbotTab:Space()

AimbotTab:Slider({
    Title = "Suavização",
    Desc = "Quão suave é a mira (maior = mais rápido)",
    Step = 0.05,
    Value = {
        Min = 0.1,
        Max = 1,
        Default = 0.5,
    },
    Callback = function(value)
        aimbot.setSmoothness(value)
    end
})

AimbotTab:Space()

AimbotTab:Input({
    Title = "FOV (Campo de Visão)",
    Desc = "Área de detecção em pixels",
    Value = "100",
    Placeholder = "100",
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            aimbot.setFOV(num)
        end
    end
})

AimbotTab:Space()

AimbotTab:Toggle({
    Title = "Verificar Parede",
    Desc = "Não mirar através de paredes",
    Value = true,
    Callback = function(state)
        aimbot.setWallCheck(state)
    end
})

AimbotTab:Space()

AimbotTab:Toggle({
    Title = "Verificar Time",
    Desc = "Ignorar jogadores do mesmo time",
    Value = true,
    Callback = function(state)
        aimbot.setTeamCheck(state)
    end
})

AimbotTab:Space()

local currentAimbotKey = "E"

local AimbotKeybind = AimbotTab:Keybind({
    Title = "Tecla para Ativar/Desativar Mira",
    Desc = "Pressione a tecla para começar/parar de mirar",
    Value = "E",
    Callback = function(key)
        currentAimbotKey = key
    end
})

AimbotTab:Space()

AutoJJSTab:Section({
    Title = "Configurações Auto JJS",
    Desc = "Automação para minigame de polichinelos.",
    TextSize = 14,
})

local AutoJJSToggle = AutoJJSTab:Toggle({
    Title = "Ativar Auto JJS",
    Desc = "Ativar cliques automáticos no minigame",
    Value = false,
    Callback = function(state)
        autoclicker.setEnabled(state, notify)
    end
})

AutoJJSTab:Space()

local AdvancedModeToggle = AutoJJSTab:Toggle({
    Title = "Modo Avançado",
    Desc = "Calcular delay automaticamente baseado em cliques/tempo",
    Value = false,
    Callback = function(state)
        autoclicker.setAdvancedMode(state)
    end
})

AutoJJSTab:Space()

AutoJJSTab:Input({
    Title = "Delay Entre Cliques",
    Desc = "Intervalo entre cada clique (segundos)",
    Value = "0.1",
    Placeholder = "0.1",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0.01 then
            autoclicker.setDelay(num)
        end
    end
})

AutoJJSTab:Space()

AutoJJSTab:Input({
    Title = "Cliques Alvo",
    Desc = "Quantidade de cliques desejada (modo avançado)",
    Value = "400",
    Placeholder = "400",
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            autoclicker.setTargetClicks(num)
        end
    end
})

AutoJJSTab:Space()

AutoJJSTab:Input({
    Title = "Tempo Alvo (segundos)",
    Desc = "Tempo total desejado (modo avançado)",
    Value = "420",
    Placeholder = "420",
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            autoclicker.setTargetTime(num)
        end
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
    
    local aimbotKey = getKeyCodeSafe(currentAimbotKey)
    if aimbotKey and inputObject.KeyCode == aimbotKey then
        if aimbot.isEnabled and not isRecordingModeEnabled and not isPlaybackModeEnabled then
            aimbot.toggleAiming()
            if aimbot.isAiming then
                notify("Aimbot", "Mira ativada", 1)
            else
                notify("Aimbot", "Mira desativada", 1)
            end
        end
    end
    
    local safeModeKey = getKeyCodeSafe(currentSafeModeKey)
    if safeModeKey and inputObject.KeyCode == safeModeKey then
        if isSafeModeEnabled and isPlaybackModeEnabled and loadedTASData and #loadedTASData > 0 then
            local firstFrameData = loadedTASData[1]
            if firstFrameData and firstFrameData.cf then
                local startPosition = Vector3.new(firstFrameData.cf[1], firstFrameData.cf[2], firstFrameData.cf[3])
                walkToPosition(startPosition, function()
                    notify("Modo Seguro", "Posição atingida", 2)
                end)
                notify("Modo Seguro", "Caminhando para posição inicial...", 2)
            end
        end
    end
    
    if inputObject.KeyCode == Enum.KeyCode.E then
        if isRecordingModeEnabled and not recording.isRecording then
            recording.beginRecording(HumanoidRootPart, Character, workspace.CurrentCamera, notify)
        elseif isPlaybackModeEnabled and not playback.isPlaying then
            tryStartPlayback()
        end
    elseif inputObject.KeyCode == Enum.KeyCode.Q then
        if isRecordingModeEnabled and recording.isRecording then
            recording.endRecording(notify)
        elseif isPlaybackModeEnabled and playback.isPlaying then
            tryStopPlayback()
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
    Title = "Sapphire.xyz",
    Content = "Carregado com sucesso",
    Duration = 3,
    Icon = "lucide:check-circle"
})
