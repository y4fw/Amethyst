local recording = {}

local RunService = game:GetService("RunService")

recording.isRecording = false
recording.recordedFrames = {}
recording.recordingConnection = nil
recording.recordingStartTimestamp = 0

function recording.captureCurrentFrame(hrp, character, camera)
    local characterCFrame = hrp.CFrame
    local characterVelocity = hrp.AssemblyLinearVelocity
    local humanoid = character:FindFirstChild("Humanoid")
    local isJumping = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Jumping
    
    local cameraCFrame = camera.CFrame
    
    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = characterCFrame:GetComponents()
    local cx, cy, cz, cr00, cr01, cr02, cr10, cr11, cr12, cr20, cr21, cr22 = cameraCFrame:GetComponents()
    
    local elapsedTime = tick() - recording.recordingStartTimestamp
    
    table.insert(recording.recordedFrames, {
        cf = {x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22},
        vel = {characterVelocity.X, characterVelocity.Y, characterVelocity.Z},
        jump = isJumping,
        cam = {cx, cy, cz, cr00, cr01, cr02, cr10, cr11, cr12, cr20, cr21, cr22},
        time = elapsedTime
    })
end

function recording.beginRecording(hrp, character, camera, notifyFunc)
    recording.recordedFrames = {}
    recording.isRecording = true
    recording.recordingStartTimestamp = tick()
    
    if recording.recordingConnection then
        recording.recordingConnection:Disconnect()
    end
    
    recording.recordingConnection = RunService.Heartbeat:Connect(function()
        if recording.isRecording then
            recording.captureCurrentFrame(hrp, character, camera)
        end
    end)
    
    notifyFunc("Gravação", "Gravação iniciada", 2)
end

function recording.endRecording(notifyFunc)
    recording.isRecording = false
    
    if recording.recordingConnection then
        recording.recordingConnection:Disconnect()
        recording.recordingConnection = nil
    end
    
    local totalDuration = #recording.recordedFrames > 0 and recording.recordedFrames[#recording.recordedFrames].time or 0
    
    notifyFunc("Gravação", string.format("Gravação parada - %d frames (%.2fs)", #recording.recordedFrames, totalDuration), 3)
end

function recording.getFrameCount()
    return #recording.recordedFrames
end

function recording.getDuration()
    return tick() - recording.recordingStartTimestamp
end

return recording
