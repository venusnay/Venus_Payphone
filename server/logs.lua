--- Main logging function for when a call ends.
--- Shared global so other files can call it.
---@param callId string
---@param caller string|number
---@param receiver string|number
---@param reason string
function LogCallEnd(callId, caller, receiver, reason)
    if not Config.Logs or not Config.Logs.enabled then return end

    local msg = string.format("Call %s ended.\n**Reason:** %s\n**From:** %s\n**To:** %s", callId, reason, tostring(caller), tostring(receiver))

    -- ox_lib log (only if available)
    if (Config.Logs.type == 'ox_lib' or Config.Logs.type == 'both') and lib and lib.logger then
        lib.logger(nil, 'call_end', {
            callId   = callId,
            reason   = reason,
            caller   = caller,
            receiver = receiver,
        })
    end

    -- Webhook log
    if Config.Logs.type == 'webhook' or Config.Logs.type == 'both' then
        -- Async SendToWebhook
        local webhook = Config.Logs.webhook
        if webhook and webhook ~= '' then
            local embed = {
                {
                    title       = "☎️ Call Ended",
                    description = msg,
                    color       = Config.Logs.color or 16711680,
                    footer      = { text = "Payphone Logs · " .. os.date("%Y-%m-%d %H:%M:%S") }
                }
            }
            PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({ username = "Payphone System", embeds = embed }), { ['Content-Type'] = 'application/json' })
        end
    end

    -- Classic console print
    print(string.format('[PAYPHONES] Log: %s', msg:gsub('\n', ' | '):gsub('%*%*', '')))
end

-- Initialize ox_lib logger tags if enabled
if Config.Logs and Config.Logs.enabled and (Config.Logs.type == 'ox_lib' or Config.Logs.type == 'both') then
    if lib and lib.logger then
        lib.logger(GetCurrentResourceName(), {
            'call_start',
            'call_end',
        })
    end
end
