local interpolation = {}

function interpolation.interpolateFrames(firstFrame, secondFrame, interpolationAlpha)
    local interpolatedFrame = {}
    
    if firstFrame.cf and secondFrame.cf then
        local cframe1 = CFrame.new(
            firstFrame.cf[1], firstFrame.cf[2], firstFrame.cf[3],
            firstFrame.cf[4], firstFrame.cf[5], firstFrame.cf[6],
            firstFrame.cf[7], firstFrame.cf[8], firstFrame.cf[9],
            firstFrame.cf[10], firstFrame.cf[11], firstFrame.cf[12]
        )
        local cframe2 = CFrame.new(
            secondFrame.cf[1], secondFrame.cf[2], secondFrame.cf[3],
            secondFrame.cf[4], secondFrame.cf[5], secondFrame.cf[6],
            secondFrame.cf[7], secondFrame.cf[8], secondFrame.cf[9],
            secondFrame.cf[10], secondFrame.cf[11], secondFrame.cf[12]
        )
        interpolatedFrame.cf = cframe1:Lerp(cframe2, interpolationAlpha)
    end
    
    if firstFrame.vel and secondFrame.vel then
        interpolatedFrame.vel = Vector3.new(
            firstFrame.vel[1] + (secondFrame.vel[1] - firstFrame.vel[1]) * interpolationAlpha,
            firstFrame.vel[2] + (secondFrame.vel[2] - firstFrame.vel[2]) * interpolationAlpha,
            firstFrame.vel[3] + (secondFrame.vel[3] - firstFrame.vel[3]) * interpolationAlpha
        )
    end
    
    if firstFrame.cam and secondFrame.cam then
        local camera1 = CFrame.new(
            firstFrame.cam[1], firstFrame.cam[2], firstFrame.cam[3],
            firstFrame.cam[4], firstFrame.cam[5], firstFrame.cam[6],
            firstFrame.cam[7], firstFrame.cam[8], firstFrame.cam[9],
            firstFrame.cam[10], firstFrame.cam[11], firstFrame.cam[12]
        )
        local camera2 = CFrame.new(
            secondFrame.cam[1], secondFrame.cam[2], secondFrame.cam[3],
            secondFrame.cam[4], secondFrame.cam[5], secondFrame.cam[6],
            secondFrame.cam[7], secondFrame.cam[8], secondFrame.cam[9],
            secondFrame.cam[10], secondFrame.cam[11], secondFrame.cam[12]
        )
        interpolatedFrame.cam = camera1:Lerp(camera2, interpolationAlpha)
    end
    
    interpolatedFrame.jump = interpolationAlpha < 0.5 and firstFrame.jump or secondFrame.jump
    
    return interpolatedFrame
end

return interpolation
