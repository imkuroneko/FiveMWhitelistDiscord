-- Datos necesarios para funcionar (bot)
discord = {
    botToken     = '',
    footerText   = 'By KuroNeko',
    iconUrl      = 'https://kuroneko.im/assets/kuroneko.png',

    serverId     = '',
    whitelistRol = '',
    channelId    = ''
}

-- Mensajes para el usuario
msg = {
    userNotOnGuild     = 'No te encuentras en el servidor de Discord.',
    notRolOnGuild      = 'No tienes el rol necesario.',
    discordNotDetected = 'No se pudo obtener tu ID de Discord para verificar tu Whitelist, tienes abierto el programa?',
    fetchingData       = 'Obteniendo tu ID de Discord, por favor aguarda',
    processingData     = 'Verificando datos',
    successLogin       = 'Datos verificados exitosamente, bienvenido!'
}

-- Mensajes para el embed
msgEmbed = {
    successLogin   = "📥 Usuario accediendo al servidor.",
    notRolOnGuild  = "⛔ Usuario sin rol de WL intenta acceder al servidor.",
    userNotOnGuild = "⛔ Usuario que no se encuentra en el Discord intenta acceder al servidor."
}

-- Tarjeta
serverCard = {
    name          = '👰🏻 KuroNeko Dev Server 🐈',
    description   = 'Servidor de FiveM para pruebas.',
    button1Text   = '💬 Discord',
    button1URL    = 'https://discord.gg/wrMcTef',
    button2Text   = '🌎 Web',
    button2URL    = 'https://kuroneko.im',
    buttonBigText = '☕ Apoyame en Ko-fi',
    buttonBigURL  = 'https://ko-fi/imkuroneko'
}


-- designer tool :: https://adaptivecardsci.z5.web.core.windows.net/pr/4005/designer#main
local card = [[
    {
        "type":"AdaptiveCard",
        "$schema":"http://adaptivecards.io/schemas/adaptive-card.json",
        "version":"1.2",
        "body":[
            { "type":"Image", "url":"https://i.imgur.com/KkVViKf.png", "horizontalAlignment":"Center" },
            {
                "type":"Container",
                "items":[
                    { "type":"TextBlock", "text":"]]..serverCard.name..[[", "wrap":true, "fontType":"Default", "size":"ExtraLarge", "weight":"Bolder", "color":"Light", "horizontalAlignment":"Center" },
                    { "type":"TextBlock", "text":"]]..serverCard.description..[[", "wrap":true, "color":"Light", "size":"Medium", "horizontalAlignment":"Center" },
                    {
                        "type":"ColumnSet",
                        "height":"stretch",
                        "minHeight":"20px",
                        "bleed":true,
                        "horizontalAlignment":"Center",
                        "columns":[
                            { "type":"Column", "width":"stretch", "height":"automatic", "items":[ { "type":"ActionSet", "actions":[ { "type":"Action.OpenUrl", "title":"]]..serverCard.button1Text..[[", "url":"]]..serverCard.button1URL..[[", "style":"positive" } ] } ] },
                            { "type":"Column", "width":"stretch", "height":"automatic", "items":[ { "type":"ActionSet", "actions":[ { "type":"Action.OpenUrl", "title":"]]..serverCard.button2Text..[[", "style":"positive", "url":"]]..serverCard.button2URL..[[" } ] } ] }
                        ]
                    },
                    { "type":"ActionSet", "actions":[ { "type":"Action.OpenUrl", "title":"]]..serverCard.button1Text..[[", "style":"destructive", "url":"]]..serverCard.button1URL..[[" } ] }
                ],
                "style":"default",
                "bleed":true,
                "height":"stretch",
                "isVisible":true
            }
        ]
    }
]]


local countWait        = 2    -- bandera de control para ocultar ventana principal
local friendlyWaitTime = 2000 -- 2seg : entre update de mensajes que se le muestra al user

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source;
    deferrals.defer();
    local toEnd = false;
    local count = 0;
    while not toEnd do
        deferrals.presentCard( card, function(data, rawData) end)
        Wait((1000))
        count = count + 1;
        if count == countWait then 
            toEnd = true;
        end
    end

    Wait(friendlyWaitTime)
    deferrals.update(msg.fetchingData)

    identifierDiscord = nil
    for k,v in pairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, string.len("discord:")) == "discord:" then
            identifierDiscord = v.gsub(v, "discord:", "")
        end
    end

    Wait(friendlyWaitTime)
    deferrals.update(msg.processingData)

    -- user data
    local name = GetPlayerName(src)
    local ip = GetPlayerEndpoint(src)
    local ping = GetPlayerPing(src)
    local steamhex = GetPlayerIdentifier(src)
    local userData = {
        { name = 'Nombre', value = name },
        { name = 'Discord ID', value = '<@'..identifierDiscord..'> ('..identifierDiscord..')' },
        { name = 'Dirección IP', value = ip },
        { name = 'Steam Hex', value = steamhex }
    }


    if identifierDiscord then
        PerformHttpRequest(
            "https://discord.com/api/guilds/"..discord.serverId.."/members/"..identifierDiscord,
            function(errorCode, resultData, resultHeaders)
                if (errorCode == 200) then
                    data = json.decode(resultData)

                    local flag = false
                    for index, str in ipairs(data.roles) do
                        if (str == discord.whitelistRol) then
                            flag = true
                        end
                    end

                    if (flag == true) then
                        deferrals.update(msg.successLogin)
                        sendEmbedToChannel(msgEmbed.successLogin, 4437349, userData)
                        Wait(friendlyWaitTime)
                        deferrals.done()
                    else
                        sendEmbedToChannel(msgEmbed.notRolOnGuild, 12402743, userData)
                        deferrals.done(msg.notRolOnGuild)
                    end
                else
                    sendEmbedToChannel(msgEmbed.userNotOnGuild, 12402743, userData)
                    deferrals.done(msg.userNotOnGuild)
                end
            end, 
            "GET", "", { ['Content-Type'] = 'application/json', ['Authorization'] = 'Bot '..discord.botToken }
        )
    else
        deferrals.done(msg.discordNotDetected)
    end
end)


function sendEmbedToChannel(ebTitle, ebColor, ebFields)
    PerformHttpRequest(
        "https://discord.com/api/channels/"..discord.channelId.."/messages",
        function(err, text, headers) end,
        "POST",
        json.encode({ tts = false, embed = { title = ebTitle, color = ebColor, fields = ebFields, footer = { text = discord.footerText, icon_url = discord.iconUrl } } }),
        { ['Content-Type'] = 'application/json', ['Authorization'] = 'Bot '..discord.botToken }
    )
end
