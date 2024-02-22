Debug = {}

function Debug.dump_to_console(obj)
    if type(obj) ~= 'table' then
        return tostring(obj)
    end

    local s = '{ '
    for k,v in pairs(obj) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. Debug.dump_to_console(v) .. ','
    end
    
    return s .. '} '
 end
