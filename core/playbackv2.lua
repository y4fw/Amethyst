local playback = {}

local RunService = game:GetService("RunService")

playback.isPlaying = false
playback.currentFrameIndex = 1
playback.playbackConnection = nil
playback.playbackStartTimestamp = 0
playback.savedAutoRotateValue = nil

function playback.startPlayback(loadedTASData, hrp, humanoid, camera, notifyFunc, onComplete, interpolationModule)
    if not loadedTASData or #loadedTASData == 0 then
        notifyFunc("Erro", "Nenhum TAS carregado", 2)
        return
    end
    
    playback.isPlaying = true
    playback.currentFrameIndex = 1
    playback.playbackStartTimestamp = tick()
    
    notifyFunc("Reprodução", "Reproduzindo TAS", 2)
    
    if playback.playbackConnection then
        playback.playbackConnection:Disconnect()
    end
    
    hrp.Anchored = false
    humanoid.PlatformStand = false
    
    playback.savedAutoRotateValue = humanoid.AutoRotate
    humanoid.AutoRotate = false
    
    playback.playbackConnection = RunService.Heartbeat:Connect(function()
        if not playback.isPlaying then
            if playback.playbackConnection then
                playback.playbackConnection:Disconnect()
                playback.playbackConnection = nil
            end
            
            hrp.Anchored = false
            humanoid.PlatformStand = false
            
            if playback.savedAutoRotateValue ~= nil then
                humanoid.AutoRotate = playback.savedAutoRotateValue
            end
            
            notifyFunc("Reprodução", "Reprodução finalizada", 2)
            if onComplete then
                onComplete()
            end
            return
        end
        
        local currentElapsedTime = tick() - playback.playbackStartTimestamp
        
        local currentFrameData = nil
        local nextFrameData = nil
        local interpolationValue = 0
        
        for frameIndex = playback.currentFrameIndex, #loadedTASData do
            if loadedTASData[frameIndex].time <= currentElapsedTime then
                currentFrameData = loadedTASData[frameIndex]
                playback.currentFrameIndex = frameIndex
                
                if frameIndex < #loadedTASData then
                    nextFrameData = loadedTASData[frameIndex + 1]
                    local timeDifference = nextFrameData.time - currentFrameData.time
                    if timeDifference > 0 then
                        interpolationValue = (currentElapsedTime - currentFrameData.time) / timeDifference
                        interpolationValue = math.clamp(interpolationValue, 0, 1)
                    end
                end
            else
                break
            end
        end
        
        if playback.currentFrameIndex >= #loadedTASData and currentElapsedTime > loadedTASData[#loadedTASData].time then
            playback.isPlaying = false
            return
        end
        
        if not currentFrameData then
            return
        end
        
        local frameToApply = currentFrameData
        if nextFrameData and interpolationValue > 0 and interpolationModule then
            frameToApply = interpolationModule.interpolateFrames(currentFrameData, nextFrameData, interpolationValue)
        end
        
        if frameToApply.vel then
            local velocityToApply
            if type(frameToApply.vel) == "table" then
                velocityToApply = Vector3.new(frameToApply.vel[1], frameToApply.vel[2], frameToApply.vel[3])
            else
                velocityToApply = frameToApply.vel
            end
            hrp.AssemblyLinearVelocity = velocityToApply
            
            local horizontalVelocity = Vector3.new(velocityToApply.X, 0, velocityToApply.Z)
            if horizontalVelocity.Magnitude > 0.5 then
                humanoid:Move(horizontalVelocity.Unit, false)
            end
        end
        
        if frameToApply.cf then
            if type(frameToApply.cf) == "table" then
                local cframeData = frameToApply.cf
                hrp.CFrame = CFrame.new(
                    cframeData[1], cframeData[2], cframeData[3],
                    cframeData[4], cframeData[5], cframeData[6],
                    cframeData[7], cframeData[8], cframeData[9],
                    cframeData[10], cframeData[11], cframeData[12]
                )
            else
                hrp.CFrame = frameToApply.cf
            end
        end
        
        if currentFrameData.jump then
            local character = hrp.Parent
            local humanoidReference = character:FindFirstChild("Humanoid")
            if humanoidReference then
                local currentState = humanoidReference:GetState()
                if currentState ~= Enum.HumanoidStateType.Jumping and currentState ~= Enum.HumanoidStateType.Freefall then
                    humanoidReference:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
        
        if frameToApply.cam then
            if type(frameToApply.cam) == "table" then
                local cameraData = frameToApply.cam
                camera.CFrame = CFrame.new(
                    cameraData[1], cameraData[2], cameraData[3],
                    cameraData[4], cameraData[5], cameraData[6],
                    cameraData[7], cameraData[8], cameraData[9],
                    cameraData[10], cameraData[11], cameraData[12]
                )
            else
                camera.CFrame = frameToApply.cam
            end
        end
    end)
end

function playback.stopPlayback(hrp, humanoid, notifyFunc, onComplete)
    playback.isPlaying = false
    if playback.playbackConnection then
        playback.playbackConnection:Disconnect()
        playback.playbackConnection = nil
    end
    
    hrp.Anchored = false
    humanoid.PlatformStand = false
    
    if playback.savedAutoRotateValue ~= nil then
        humanoid.AutoRotate = playback.savedAutoRotateValue
    end
    
    if onComplete then
        onComplete()
    end
    
    notifyFunc("Reprodução", "Reprodução parada", 2)
end

return playback