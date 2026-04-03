local storage = {}

storage.tasStorageFolder = "AmethystTAS"

function storage.initialize()
    if not isfolder(storage.tasStorageFolder) then
        makefolder(storage.tasStorageFolder)
    end
end

function storage.getTASFileList()
    local fileList = {}
    
    if not isfolder(storage.tasStorageFolder) then
        return fileList
    end
    
    local success, files = pcall(function()
        return listfiles(storage.tasStorageFolder)
    end)
    
    if not success or not files then
        return fileList
    end
    
    for _, filePath in ipairs(files) do
        local fileName = filePath:match("([^/\\]+)$")
        if fileName and fileName:match("%.json$") then
            local nameWithoutExtension = fileName:gsub("%.json$", "")
            table.insert(fileList, nameWithoutExtension)
        end
    end
    
    return fileList
end

function storage.serializeTASData(recordedFrames)
    local HttpService = game:GetService("HttpService")
    local dataStructure = {
        Version = 2,
        Frames = recordedFrames,
        Duration = #recordedFrames > 0 and recordedFrames[#recordedFrames].time or 0
    }
    return HttpService:JSONEncode(dataStructure)
end

function storage.saveTASToFile(fileName, recordedFrames, notifyFunc)
    if #recordedFrames == 0 then
        notifyFunc("Erro", "Nenhum frame para salvar", 2)
        return false
    end
    
    if not fileName or fileName == "" then
        notifyFunc("Erro", "Digite um nome para o TAS", 2)
        return false
    end
    
    local serializedData = storage.serializeTASData(recordedFrames)
    local fullFilePath = storage.tasStorageFolder .. "/" .. fileName .. ".json"
    
    writefile(fullFilePath, serializedData)
    
    local totalDuration = #recordedFrames > 0 and recordedFrames[#recordedFrames].time or 0
    notifyFunc("Sucesso", string.format("TAS '%s' salvo (%d frames, %.2fs)", fileName, #recordedFrames, totalDuration), 3)
    
    return true
end

function storage.loadTASFromFile(fileName, notifyFunc)
    if not fileName or fileName == "" then
        notifyFunc("Erro", "Selecione um TAS para carregar", 2)
        return nil
    end
    
    local fullFilePath = storage.tasStorageFolder .. "/" .. fileName .. ".json"
    
    if not isfile(fullFilePath) then
        notifyFunc("Erro", "Arquivo não encontrado", 2)
        return nil
    end
    
    local fileContent = readfile(fullFilePath)
    local HttpService = game:GetService("HttpService")
    local parseSuccess, parsedData = pcall(function()
        return HttpService:JSONDecode(fileContent)
    end)
    
    if parseSuccess and parsedData.Frames then
        local totalDuration = parsedData.Duration or (#parsedData.Frames > 0 and parsedData.Frames[#parsedData.Frames].time or 0)
        notifyFunc("TAS Carregado", string.format("'%s' carregado (%d frames, %.2fs)", fileName, #parsedData.Frames, totalDuration), 3)
        return parsedData.Frames
    else
        notifyFunc("Erro", "Falha ao carregar TAS", 3)
        return nil
    end
end

function storage.deleteTASFile(fileName, notifyFunc)
    if not fileName or fileName == "" then
        return false
    end
    
    local fullFilePath = storage.tasStorageFolder .. "/" .. fileName .. ".json"
    
    if not isfile(fullFilePath) then
        notifyFunc("Erro", "Arquivo não encontrado", 2)
        return false
    end
    
    delfile(fullFilePath)
    
    notifyFunc("Sucesso", "TAS '" .. fileName .. "' deletado", 2)
    
    return true
end

return storage
