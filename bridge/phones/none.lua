if Config.PhoneSystem == 'none' then
    PhoneBridge = {
        CreateCall = function(source, payphoneId, payphoneNumber, targetNumber)
            return nil
        end,
        EndCall = function(source)
            -- Do nothing
        end,
        IsInCall = function(source)
            return false, nil, nil
        end
    }
end
