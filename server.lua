-- Datos necesarios para interactuar con Discord
discord = {
    botToken     = '',
    serverId     = '',
    whitelistRol = ''
}

-- Mensajes
msg = {
    userNotOnGuild     = 'No te encuentras en el servidor de Discord.',
    notRolOnGuild      = 'No tienes el rol necesario.',
    discordNotDetected = 'No se pudo obtener tu ID de Discord para verificar tu Whitelist, tienes abierto el programa?',
    fetchingData       = 'Obteniendo tu ID de Discord, por favor aguarda',
    processingData     = 'Verificando datos',
    successLogin       = 'Datos verificados exitosamente, bienvenido!'
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
                    { "type":"TextBlock", "text":"👰🏻 KuroNeko Dev Server 🐈", "wrap":true, "fontType":"Default", "size":"ExtraLarge", "weight":"Bolder", "color":"Light", "horizontalAlignment":"Center" },
                    { "type":"TextBlock", "text":"Servidor de FiveM privados para fines de desarrollo. El acceso al mismo es limitado y estrictamente verificado por la progamadora 💜", "wrap":true, "color":"Light", "size":"Medium", "horizontalAlignment":"Center" },
                    {
                        "type":"ColumnSet",
                        "height":"stretch",
                        "minHeight":"20px",
                        "bleed":true,
                        "horizontalAlignment":"Center",
                        "columns":[
                            {
                                "type":"Column",
                                "width":"stretch",
                                "height":"automatic",
                                "items":[ { "type":"ActionSet", "actions":[ { "type":"Action.OpenUrl", "title":"💬 Discord", "url":"https://discord.gg/wrMcTef", "style":"positive" } ] } ]
                            },
                            {
                                "type":"Column",
                                "width":"stretch",
                                "height":"automatic",
                                "items":[ { "type":"ActionSet", "actions":[ { "type":"Action.OpenUrl", "title":"🌎 Web", "style":"positive", "url":"https://kuroneko.im" } ] } ]
                            }
                        ]
                    },
                    {
                        "type":"ActionSet",
                        "actions":[
                            {
                                "type":"Action.OpenUrl",
                                "title":"☕ Apoyame en Ko-fi",
                                "style":"destructive",
                                "url":"https://ko-fi/imkuroneko"
                            }
                        ]
                    }
                ],
                "style":"default",
                "bleed":true,
                "height":"stretch",
                "isVisible":true
            }
        ]
    }
]]

local countWait = 10
local friendlyWaitTime = 2000 -- 2seg (para entre mensajes de procesando y demas...)

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
    print('verificando datos de: '..name)

    identifierDiscord = nil
    for k,v in pairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, string.len("discord:")) == "discord:" then
            identifierDiscord = v.gsub(v, "discord:", "")
        end
    end

    Wait(friendlyWaitTime)
    deferrals.update(msg.processingData)

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
                        print(name..' ha accedido exitosamente')
                        deferrals.update(msg.successLogin)
                        Wait(friendlyWaitTime)
                        deferrals.done()
                    else
                        print(name..' no tiene el rol necesario')
                        deferrals.done(msg.notRolOnGuild)
                    end
                else
                    deferrals.done(msg.userNotOnGuild)
                end
            end, 
            "GET", "", { ['Content-Type'] = 'application/json', ['Authorization'] = 'Bot '..discord.botToken }
        )
    else
        deferrals.done(msg.discordNotDetected)
    end

end)