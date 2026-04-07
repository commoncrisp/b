local HttpService = game:GetService("HttpService")

local function send(content, dlog, webhookUrl)
    if not webhookUrl or webhookUrl == "" then
        dlog("ERROR: No webhook URL provided")
        return
    end

    local chunks = {}
    while #content > 1900 do
        local cutAt = content:sub(1, 1900):find("\n[^\n]*$") or 1900
        table.insert(chunks, content:sub(1, cutAt))
        content = content:sub(cutAt + 1)
    end
    table.insert(chunks, content)
    dlog("Sending " .. #chunks .. " chunk(s) to webhook...")

    for i, chunk in ipairs(chunks) do
        local ok, err = pcall(function()
            request({
                Url = webhookUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ content = chunk })
            })
        end)
        if ok then
            dlog("Chunk " .. i .. " sent OK")
        else
            dlog("ERROR on chunk " .. i .. ": " .. tostring(err))
        end
        task.wait(0.5)
    end
end

local function sendEmbed(title, description, color, dlog, webhookUrl)
    if not webhookUrl or webhookUrl == "" then
        dlog("ERROR: No webhook URL provided")
        return
    end

    local ok, err = pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                embeds = {{
                    title = title,
                    description = description,
                    color = color or 3066993
                }}
            })
        })
    end)
    if not ok then
        dlog("ERROR sending embed: " .. tostring(err))
    end
end

return {
    send = send,
    sendEmbed = sendEmbed
}