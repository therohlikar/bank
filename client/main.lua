local isSpawned, isDead, isOpened, pCoords, isOpened, isInMachine = false, false, false, nil, 0, false
local jobName, jobGrade, charId = nil, nil, nil 
local publicBlips = {}

local closestAtm = nil 

local openedAccounts = nil 

Citizen.CreateThread(function()
    Citizen.Wait(500)

    local status = exports.data:getUserVar("status")
    if status == "spawned" or status == "dead" then 
        isSpawned = true
        isDead = (status == "dead")

        if charId == nil then 
            jobName = exports.data:getCharVar("job")
            jobGrade = exports.data:getCharVar("job_grade")
            charId = exports.data:getCharVar("id")
        end

        if #publicBlips == 0 then 
            createBankBlips()
        end
    end
end)

RegisterNetEvent("s:statusUpdated")
AddEventHandler("s:statusUpdated",
    function(status)
        if status == "spawned" or "dead" then 
            isSpawned = true
            isDead = (status == "dead")

            if isDead then 
                if isOpened > 0 then 
                    close()
                end
            end

            if #publicBlips == 0 then 
                createBankBlips()
            end

            if charId == nil then 
                jobName = exports.data:getCharVar("job")
                jobGrade = exports.data:getCharVar("job_grade")
                charId = exports.data:getCharVar("id")
            end
        end
    end
)

RegisterNetEvent("s:jobUpdated")
AddEventHandler("s:jobUpdated",
    function(job, grade, duty)
        if job ~= nil and grade ~= nil and (jobName ~= job or jobGrade ~= grade) and isOpened then 
            SendNUIMessage({
                action = "updatejob",
                job = {
                    name = job,
                    grade = grade
                }
            })
        end
        jobName = job
        jobGrade = grade
    end
)

RegisterNetEvent("inventory:usedItem")
AddEventHandler("inventory:usedItem", 
	function(itemName, slot, data, slot)
		if itemName == "bankcard" then 
            if closestAtm ~= nil then 
                local oCoords = GetEntityCoords(closestAtm)
                local distance = GetDistanceBetweenCoords(pCoords, oCoords, true)

                if distance < 3.0 then 
                    TriggerServerEvent("bank:openCashMachine", data.id, data.account)
                end
            end
        end
    end
)

RegisterNetEvent("bank:openCashMachine")
AddEventHandler("bank:openCashMachine", 
	function(cardId, data)
        if data == nil then 
            exports.notify:display({type = "error", title = "Banka", text = "Zdá se, že karta neexistuje", icon = "fas fa-dollar-sign", length = 3500})
        else
            if data.cards[cardId] ~= nil then 
                if data.cards[cardId].blocked > 0 then 
                    exports.notify:display({type = "warning", title = "Banka", text = "Karta, kterou chcete použít, je systémem blokována", icon = "fas fa-dollar-sign", length = 3500})
                else 
                    openedAccounts = {
                        [data.number] = data
                    } 
                    openCashMachine(cardId, data)
                end
            else 
                exports.notify:display({type = "warning", title = "Banka", text = "Karta, kterou chcete použít, je systémem blokována nebo neexistuje", icon = "fas fa-dollar-sign", length = 3500})
            end
        end
    end
)

RegisterNUICallback("closepanel", function(data, cb) close() end)
RegisterNUICallback("notify", function(data, cb) 
    exports.notify:display({type = data.type, title = data.title, text = data.text, icon = "fas fa-dollar-sign", length = 2500})
end)

RegisterNUICallback("action", function(data, cb) 
    if data.action == "withdraw-take" then 
        if type(data.value) ~= "number" then 
            data.value = tonumber(data.value)
        end

        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end

        TriggerServerEvent("bank:withdraw", data.account, data.value, "take")
    elseif data.action == "withdraw-put" then 
        if type(data.value) ~= "number" then 
            data.value = tonumber(data.value)
        end

        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end

        TriggerServerEvent("bank:withdraw", data.account, data.value, "put")
    elseif data.action == "transfer" then 
        if type(data.value) ~= "number" then 
            data.value = tonumber(data.value)
        end

        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end

        if type(data.target) ~= "string" then 
            data.target = tostring(data.target)
        end

        TriggerServerEvent("bank:transfer", data.account, data.target, data.value)
    elseif data.action == "createaccount" then
        TriggerServerEvent("bank:create", {
            ["id"] = charId,
            ["name"] = exports.data:getCharVar("firstname") .. " " .. exports.data:getCharVar("lastname")
        }, {
            type = data.type,
            job = jobName,
            grade = jobGrade
        })
    elseif data.action == "rename" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end

        TriggerServerEvent("bank:rename", data.account, data.value)
    elseif data.action == "changetype" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        local sendData = {}

        if data.type == "company" then 
            sendData = {
                ["name"] = jobName,
                ["grade"] = jobGrade
            }        
        end
        TriggerServerEvent("bank:type", data.account, data.type, sendData)
    elseif data.action == "changefounder" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        
        TriggerEvent("util:closestPlayer",{
            radius = 2.0
        }, 
        function(target)
            if target then 
                TriggerServerEvent("bank:founder", data.account, target)
            end
        end)
    elseif data.action == "access-add" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        
        TriggerEvent("util:closestPlayer",{
            radius = 2.0
        }, 
        function(target)
            if target then 
                TriggerServerEvent("bank:access", data.account, "add", target)
            end
        end)
    elseif data.action == "access-remove" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end

        if type(data.target) ~= "number" then 
            data.target = tonumber(data.target)
        end

        TriggerServerEvent("bank:access", data.account, "remove", data.target)
    elseif data.action == "delete" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        
        TriggerServerEvent("bank:delete", data.account)
    elseif data.action == "updatepermission" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end

        if type(data.target) ~= "number" then 
            data.target = tonumber(data.target)
        end
        TriggerServerEvent("bank:setpermissions", data.account, data.target, data.current)
    elseif data.action == "createcard" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        
        TriggerServerEvent("bank:createcard", data.account, data.code)
    elseif data.action == "blockcard" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        
        if type(data.card) ~= "string" then 
            data.card = tostring(data.card)
        end

        TriggerServerEvent("bank:blockcard", data.account, data.card, data.type)
    elseif data.action == "renamecard" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        
        if type(data.card) ~= "string" then 
            data.card = tostring(data.card)
        end

        TriggerServerEvent("bank:renamecard", data.account, data.card, data.name)
    elseif data.action == "deletecard" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        
        if type(data.card) ~= "string" then 
            data.card = tostring(data.card)
        end

        TriggerServerEvent("bank:deletecard", data.account, data.card)
    elseif data.action == "setinvoicepaid" then 
        if type(data.account) ~= "string" then 
            data.account = tostring(data.account)
        end
        
        if type(data.invoiceId) ~= "string" then 
            data.invoiceId = tostring(data.invoiceId)
        end

        TriggerServerEvent("bank:setinvoicepaid", data.account, data.invoiceId)
    elseif data.action == "payinvoice" then 
        if data.type == "bank" then 
            if type(data.account) ~= "string" then 
                data.account = tostring(data.account)
            end

            TriggerServerEvent("invoices:pay", data.invoice, data.account, true)
        else
            if type(data.invoiceId) ~= "string" then 
                data.invoiceId = tostring(data.invoiceId)
            end

            TriggerServerEvent("bank:payInvoice", data.invoiceId, data.price)
        end
    elseif data.action == "payfine" then 
        if data.type == "bank" then 
            if type(data.account) ~= "string" then 
                data.account = tostring(data.account)
            end
            
            TriggerServerEvent("fines:pay", data.fineId, data.account)
        else
            if type(data.fineId) ~= "number" then 
                data.fineId = tonumber(data.fineId)
            end
            
            TriggerServerEvent("fines:pay", data.fineId)
        end
    end
end)

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(2000)
        if isSpawned and not isDead then 
            pCoords = GetEntityCoords(GetPlayerPed(-1), false)
        end
    end
end)

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(2000)
        if isSpawned and not isDead and pCoords ~= nil then
            for i=1, #Config.ATMs do 
                local object = GetClosestObjectOfType(pCoords.x, pCoords.y, pCoords.z, 1.2, GetHashKey(Config.ATMs[i]), false, false, false)
                if DoesEntityExist(object) then
                    local oCoords = GetEntityCoords(object)
                    local dist = #(pCoords - oCoords)
                    if dist < 3.0 then 
                        closestAtm = object
                    end 
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(1)
        if isSpawned and not isDead then
            for i=1, #Config.banks do 
                if Config.banks[i]["available"] then 
                    local distance = GetDistanceBetweenCoords(pCoords, Config.banks[i]["coords"]["x"], Config.banks[i]["coords"]["y"], Config.banks[i]["coords"]["z"], true)

                    if distance < Config.banks[i]["distance"] then
                        DrawMarker(Config.banks[i]["mType"], Config.banks[i]["coords"]["x"], Config.banks[i]["coords"]["y"], Config.banks[i]["coords"]["z"]-0.95, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.2, 1.2, 1.2, Config.banks[i]["mColor"].r, Config.banks[i]["mColor"].g, Config.banks[i]["mColor"].b, 100, false, true, 2, true, false, false, false)
                        if distance < Config.banks[i]["range"] then 
                            exports.font:DrawText3D(Config.banks[i]["coords"]["x"], Config.banks[i]["coords"]["y"], Config.banks[i]["coords"]["z"]-0.5, Config.banks[i]["label"])
                            if IsControlJustReleased(1, Config.openMenuKey) then 
                                isOpened = i 
                                TriggerServerEvent("bank:open", jobName, jobGrade, charId)
                            end
                        end
                    else 
                        if isOpened == i then 
                            close()
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("bank:sync")
AddEventHandler("bank:sync", function(data)
    update(data)
end)

RegisterNetEvent("bank:open")
AddEventHandler("bank:open", function(data, count)
    openedAccounts = data 
    openBankMenu(data, count)
end)

RegisterNetEvent("bank:withdraw")
AddEventHandler("bank:withdraw", function(status, type)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Požadavek zpracován", text = "Požadavek byl zpracován.", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        if type == "put" then 
            exports.notify:display({type = "warning", title = "Požadavek nezpracován", text = "Požadavek nebyl zpracován. Nemáte u sebe dostatek peněz.", icon = "fas fa-dollar-sign", length = 3500})
        else
            exports.notify:display({type = "warning", title = "Požadavek nezpracován", text = "Požadavek nebyl zpracován. Nedostatečný zůstatek na bankovním účtě.", icon = "fas fa-dollar-sign", length = 3500})
        end
    end
end)

RegisterNetEvent("bank:transfer")
AddEventHandler("bank:transfer", function(status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Požadavek zpracován", text = "Požadavek byl zpracován.", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        local additionalString = "Nedostatečný zůstatek na bankovním účtě."
        if status == "missingTargetAccount" then 
            additionalString = "Vámi zadaný protúčet neexistuje."
        elseif status == "sameAccount" then 
            additionalString = "Zadaný účet se shoduje s vaším účtem."
        end
        exports.notify:display({type = "warning", title = "Požadavek nezpracován", text = "Požadavek nebyl zpracován. " .. additionalString, icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:delete")
AddEventHandler("bank:delete", function(status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Zrušení účtu", text = "Mrzí nás, že odcházíte. Budeme se na vás případně těšit.", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        if status == "balanceNegative" then 
            exports.notify:display({type = "warning", title = "Zrušení účtu", text = "Účet má negativní zůstatek, nelze ho smazat.", icon = "fas fa-dollar-sign", length = 3500})
        else
            exports.notify:display({type = "warning", title = "Zrušení účtu", text = "Účet má na sobě kladný zůstatek. Dokud to tak bude, účet zrušit bohužel nemůžeme.", icon = "fas fa-dollar-sign", length = 3500})
        end
    end
end)

RegisterNetEvent("bank:rename")
AddEventHandler("bank:rename", function(status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Požadavek zpracován", text = "Požadavek byl zpracován.", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        exports.notify:display({type = "warning", title = "Požadavek nezpracován", text = "Požadavek nebyl zpracován.", icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:setinvoicepaid")
AddEventHandler("bank:setinvoicepaid", function(invoiceId, status, invoices)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Požadavek zpracován", text = "Požadavek byl zpracován.", icon = "fas fa-dollar-sign", length = 2000})
        if invoices ~= nil then 
            SendNUIMessage({
                action = "updatepersonalinvoices",
                data = invoices
            })
        end
    else 
        print("[BANK] Failed with reason: " .. status)
        exports.notify:display({type = "warning", title = "Požadavek nezpracován", text = "Požadavek nebyl zpracován.", icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:payFine")
AddEventHandler("bank:payFine", function(status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Požadavek zpracován", text = "Požadavek byl zpracován.", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        exports.notify:display({type = "warning", title = "Požadavek nezpracován", text = "Požadavek nebyl zpracován.", icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:refreshFines")
AddEventHandler("bank:refreshFines", function(status, fines)
    if status == "done" then 
        if fines ~= nil then 
            SendNUIMessage({
                action = "updatefines",
                data = fines
            })
        end
    end
end)

RegisterNetEvent("bank:type")
AddEventHandler("bank:type", function(status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Požadavek zpracován", text = "Požadavek byl zpracován.", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        exports.notify:display({type = "warning", title = "Požadavek nezpracován", text = "Požadavek nebyl zpracován.", icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:founder")
AddEventHandler("bank:founder", function(status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Změna správce účtu", text = "Požadavek byl zpracován.", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        exports.notify:display({type = "warning", title = "Změna správce účtu", text = "Požadavek nebyl zpracován.", icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:create")
AddEventHandler("bank:create", function(status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Otevření nového bankovního účtu", text = "Gratulujeme! Otevřeli jsme pro vás nový bankovní účet", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        if status == "noPermission" then 
            exports.notify:display({type = "warning", title = "Otevření nového bankovního účtu", text = "Je nám líto, ale pro vytvoření firemního účtu nemáte dostatečné pravomoce", icon = "fas fa-dollar-sign", length = 3500})
        else 
            exports.notify:display({type = "warning", title = "Otevření nového bankovního účtu", text = "Je nám líto, ale účet jsme vám nedokázali otevřít.", icon = "fas fa-dollar-sign", length = 3500})
        end
    end
end)

RegisterNetEvent("bank:createcard")
AddEventHandler("bank:createcard", function(status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Založení platební karty", text = "Vaše nová platební karta byla vytvořena", icon = "fas fa-dollar-sign", length = 2000})
    else 
        print("[BANK] Failed with reason: " .. status)
        if status == "maxCards" then 
            exports.notify:display({type = "warning", title = "Založení platební karty", text = "Bohužel jste přesáhl maximální povolený počet platebních karet (" .. Config.maxCards .. ")", icon = "fas fa-dollar-sign", length = 3500})
        else 
            exports.notify:display({type = "warning", title = "Založení platební karty", text = "Je nám líto, ale někde nastala chyba při vytváření karty", icon = "fas fa-dollar-sign", length = 3500})
        end
    end
end)

RegisterNetEvent("bank:blockcard")
AddEventHandler("bank:blockcard", function(cardId, status)
    if status == "blocked" then 
        exports.notify:display({type = "success", title = "Blokace platební karty", text = "Blokace platební karty " .. cardId .. " proběhla úspěšně.", icon = "fas fa-dollar-sign", length = 2000})
    elseif status == "unblocked" then 
        exports.notify:display({type = "success", title = "Odblokace platební karty", text = "Odblokace platební karty " .. cardId .. " proběhla úspěšně.", icon = "fas fa-dollar-sign", length = 2000})
    else
        print("[BANK] Failed with reason: " .. status)
        exports.notify:display({type = "warning", title = "Blokace/Odblokace platební karty", text = "Je nám líto, ale někde nastala chyba při blokace karty", icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:renamecard")
AddEventHandler("bank:renamecard", function(cardId, status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Zpracování požadavku", text = "Požadavek úspěšně zpracován.", icon = "fas fa-dollar-sign", length = 2000})
    else
        print("[BANK] Failed with reason: " .. status)
        exports.notify:display({type = "warning", title = "Zpracování požadavku", text = "Je nám líto, ale někde nastala chyba při změně názvu karty", icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:deletecard")
AddEventHandler("bank:deletecard", function(cardId, status)
    if status == "done" then 
        exports.notify:display({type = "success", title = "Zrušení platební karty", text = "Zrušení platební karty proběhlo v pořádku.", icon = "fas fa-dollar-sign", length = 2000})
    else
        print("[BANK] Failed with reason: " .. status)
        exports.notify:display({type = "warning", title = "Zrušení platební karty", text = "Je nám líto, ale někde nastala chyba při zrušení platební karty", icon = "fas fa-dollar-sign", length = 3500})
    end
end)

RegisterNetEvent("bank:access")
AddEventHandler("bank:access", function(action, status)
    if action == "add" then 
        if status == "done" then 
            exports.notify:display({type = "success", title = "Přidání oprávnění", text = "Osoba byla připsána na účet jako správce", icon = "fas fa-dollar-sign", length = 2000})
        else 
            print("[BANK] Failed with reason: " .. status)
            exports.notify:display({type = "warning", title = "Přidání oprávnění", text = "Osoba již přístup na váš účet má", icon = "fas fa-dollar-sign", length = 3500})
        end
    elseif action == "remove" then 
        if status == "done" then 
            exports.notify:display({type = "success", title = "Odebrání oprávnění", text = "Osobu jsme odebrali z přístupu", icon = "fas fa-dollar-sign", length = 2000})
        else 
            print("[BANK] Failed with reason: " .. status)
            exports.notify:display({type = "warning", title = "Odebrání oprávnění", text = "Osoba přístup žádný nemá", icon = "fas fa-dollar-sign", length = 3500})
        end
    elseif action == "check" then 
        if status then 
            exports.notify:display({type = "success", title = "Kontrola oprávnění", text = "Osoba, kterou kontrolujete, je v seznamu správců", icon = "fas fa-dollar-sign", length = 2000})
        else 
            print("[BANK] Failed with reason: " .. status)
            exports.notify:display({type = "warning", title = "Přidání oprávnění", text = "Osoba, kterou kontrolujete, není v seznamu správců", icon = "fas fa-dollar-sign", length = 3500})
        end
    end
end)

function openBankMenu(data, count)
    SendNUIMessage({
        action = "show",
        accounts = data,
        settings = {
            count = count,
            maxAccounts = Config.maxAvailableAccounts,
            job = {
                name = jobName,
                grade = jobGrade
            },
            charId = charId
        }
    })
    SetNuiFocus(true, true)
end

function openCashMachine(cardId, account)
    isInMachine = true
    SendNUIMessage({
        action = "show-machine",
        account = account,
        cardId = cardId,
        settings = {
            job = {
                name = jobName,
                grade = jobGrade
            },
            charId = charId
        }
    })
    SetNuiFocus(true, true)
end

function close()
    SendNUIMessage({action = "hide"}) 
    SetNuiFocus(false, false)
    openedAccounts = nil 
    isInMachine = false 
    isOpened = 0 
end

function update(data)
    if (isOpened > 0 or isInMachine)and openedAccounts ~= nil and openedAccounts[data.number] ~= nil then 
        openedAccounts[data.number] = data 
        SendNUIMessage({
            action = "updateaccount",
            account = data
        })
    end
end

local lendAccounts = nil 

function openBankAccountList(charId, jobName, jobGrade, func)
    if charId == nil or jobName == nil or jobGrade == nil or func == nil then 
        return "missingVariables"
    end
    lendAccounts = nil 

    TriggerServerEvent("bank:createBankAccountList", charId, jobName, jobGrade)

    local tryOut = 0
    while lendAccounts == nil do 
        Citizen.Wait(50)
        tryOut = tryOut + 1
        if tryOut > 50 then 
            return "timeOut"
        end
    end
    WarMenu.CreateMenu("bankAccsList", "Bankovní účet", "Zvole ucet")
    WarMenu.SetMenuY("bankAccsList", 0.35)
    WarMenu.OpenMenu("bankAccsList")

    while true do
        if WarMenu.IsMenuOpened("bankAccsList") then
            for i=1, #lendAccounts.list do
                if WarMenu.Button(lendAccounts.list[i]["number"] .. " ~g~$" .. lendAccounts.list[i]["balance"]) then 
                    func(lendAccounts.list[i]["number"])
                    WarMenu.CloseMenu()
                end
            end
            WarMenu.Display()
        else 
            func("closed")
            break 
        end 
        Citizen.Wait(0)
    end

    lendAccounts = nil 
    return "done"
end 

RegisterNetEvent("bank:createBankAccountList")
AddEventHandler("bank:createBankAccountList", 
    function(list, count)
        lendAccounts = {
            list = list,
            count = count 
        } 
    end
)

function createBankBlips()
    if #publicBlips <= 0 then 
        for i=1, #Config.banks do 
            local company = Config.banks[i]["company"]
            if not Config.banks[i]["hidden"] then 
                local blip = AddBlipForCoord(Config.banks[i]["coords"]["x"], Config.banks[i]["coords"]["y"], Config.banks[i]["coords"]["z"])

                SetBlipSprite(blip, Config.blips[company]["bType"])
                SetBlipDisplay(blip, Config.blips[company]["bDisplay"])
                SetBlipScale(blip, Config.blips[company]["bScale"])
                SetBlipColour(blip, Config.blips[company]["bColor"])
                SetBlipAsShortRange(blip, true)
        
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(Config.blips[company]["bLabel"])
                EndTextCommandSetBlipName(blip)
        
                table.insert(publicBlips, blip)
            end
        end
    end
end