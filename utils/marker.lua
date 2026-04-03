local marker = {}

marker.startPositionMarker = nil

function marker.createStartPositionMarker(position)
    if marker.startPositionMarker then
        marker.startPositionMarker:Destroy()
    end
    
    local markerPart = Instance.new("Part")
    markerPart.Size = Vector3.new(8, 10, 8)
    markerPart.Position = position
    markerPart.Anchored = true
    markerPart.CanCollide = false
    markerPart.Transparency = 0.7
    markerPart.Color = Color3.fromRGB(0, 255, 0)
    markerPart.Material = Enum.Material.Neon
    markerPart.Parent = workspace
    
    marker.startPositionMarker = markerPart
    return markerPart
end

function marker.destroyMarker()
    if marker.startPositionMarker then
        marker.startPositionMarker:Destroy()
        marker.startPositionMarker = nil
    end
end

return marker
