local accounts = {} 
local accountsToSave = {}
MySQL.ready(function()
    Wait(5)
   
    MySQL.Async.fetchAll(
        "SELECT * FROM bank_accounts",
        {},
        function(result)
            for i=1, #result do 
                accounts[result[i]["number"]] = {
                    number = result[i].number,
                    description = result[i].description,
                    founder = json.decode(result[i].founder),
                    access_list = json.decode(result[i].access_list),
                    balance = result[i].balance,
                    cards = json.decode(result[i].cards),
                    changed = false 
                }
            end
        end
    )

    SetTimeout(25000, saveAccounts)
end)

function saveAccounts()
    for i=1, #accountsToSave do 
        local bankAccount = accountsToSave[i]
        if type(bankAccount) ~= "string" then bankAccount = tostring(bankAccount) end 
        if accounts[bankAccount] ~= nil and accounts[bankAccount].changed then 
            table.remove(accountsToSave, i)
            accounts[bankAccount].changed = false 
            MySQL.Async.execute(
                "UPDATE bank_accounts SET founder = @founder, description = @description, access_list = @access_list, cards = @cards, balance = @balance WHERE number = @number",
                {
                    ["@number"] = accounts[bankAccount].number,
                    ["@founder"] = json.encode(accounts[bankAccount].founder),
                    ["@description"] = accounts[bankAccount].description,
                    ["@access_list"] = json.encode(accounts[bankAccount].access_list),
                    ["@cards"] = json.encode(accounts[bankAccount].cards),
                    ["@balance"] = accounts[bankAccount].balance
                }
            )

            print("BANK ACCOUNT SAVED: " .. bankAccount)
        end
    end

    SetTimeout(25000, saveAccounts)
end

RegisterServerEvent("bank:openCashMachine")
AddEventHandler(
    "bank:openCashMachine",
    function(cardId, sourceAccount)
        local _source = source 
        TriggerClientEvent("bank:openCashMachine", _source, cardId, accounts[sourceAccount])
    end
)

RegisterServerEvent("bank:open")
AddEventHandler(
    "bank:open",
    function(jobName, jobGrade, charId)
        local _source = source 
        local accessed, count = getAccessableAccounts(charId, jobName, jobGrade, true, true, true, true)
        TriggerClientEvent("bank:open", _source, accessed, count)
    end
)

RegisterServerEvent("bank:createBankAccountList")
AddEventHandler(
    "bank:createBankAccountList",
    function(charId, jobName, jobGrade)
        local _source = source 
        local accessed, count = getAccessableAccounts(charId, jobName, jobGrade, false, false, false, false)
        TriggerClientEvent("bank:createBankAccountList", _source, accessed, count)
    end
)

RegisterServerEvent("bank:withdraw")
AddEventHandler(
    "bank:withdraw",
    function(sourceAccount, value, type)
        local _source = source 
        local done = withdraw(_source, sourceAccount, value, type, true)
        TriggerClientEvent("bank:withdraw", _source, done, type)
    end
)

RegisterServerEvent("bank:transfer")
AddEventHandler(
    "bank:transfer",
    function(sourceAccount, targetAccount, value)
        local _source = source 
        local done = transferFunds(sourceAccount, targetAccount, value, true)
        TriggerClientEvent("bank:transfer", _source, done)
    end
)

RegisterServerEvent("bank:rename")
AddEventHandler(
    "bank:rename",
    function(sourceAccount, value)
        local _source = source 
        local done = renameAccount(sourceAccount, value)
        TriggerClientEvent("bank:rename", _source, done)
    end
)

RegisterServerEvent("bank:delete")
AddEventHandler(
    "bank:delete",
    function(sourceAccount, value)
        local _source, done = source, "balanceNotZero" 
        if accounts[sourceAccount].balance == 0 then 
            done = delete(sourceAccount)
        elseif accounts[sourceAccount].balance < 0 then 
            done = "balanceNegative"
        end

        TriggerClientEvent("bank:delete", _source, done)
    end
)

RegisterServerEvent("bank:founder")
AddEventHandler(
    "bank:founder",
    function(sourceAccount, newFounder)
        local _source = source 
        local done = changeOwner(sourceAccount, {
            ["id"] = exports.data:getCharVar(newFounder, "id"),
            ["name"] = exports.data:getCharVar(newFounder, "firstname") .. " " .. exports.data:getCharVar(newFounder, "lastname")
        })
        TriggerClientEvent("bank:founder", _source, done)
        TriggerClientEvent("bank:founder", newFounder, done)
    end
)

RegisterServerEvent("bank:type")
AddEventHandler(
    "bank:type",
    function(sourceAccount, newType, newData)
        local _source, done = source, "noPermission"
        if newType ~= "company" then 
            done = changeType(sourceAccount, newType, newData)
        else 
            local gradeRank = exports.data:getJobGradeVar(newData.name, newData.grade, "rank")
            if gradeRank == "boss" then 
                done = changeType(sourceAccount, newType, newData)
            else done = "noPermission" end
        end
        TriggerClientEvent("bank:type", _source, done)
    end
)

RegisterServerEvent("bank:create")
AddEventHandler(
    "bank:create",
    function(founder, typedata)
        local _source, accountnumber, done = source, nil, "missingVariable" 
        if founder ~= nil and founder.id ~= nil and founder.name ~= nil then 
            if typedata.type ~= "company" then 
                done = create(founder, 0, typedata, exports.data:getUserVar(_source, "connectionTime"))
            else 
                local gradeRank = exports.data:getJobGradeVar(typedata.job, typedata.grade, "rank")
                if gradeRank == "boss" then 
                    done = create(founder, 0, typedata, exports.data:getUserVar(_source, "connectionTime"))
                else done = "noPermission" end
            end
        end
        TriggerClientEvent("bank:create", _source, done)
    end
)

RegisterServerEvent("bank:access")
AddEventHandler(
    "bank:access",
    function(sourceAccount, action, data)
        local _source, done = source, "hasAccess"
        if action == "add" then 
            done = addAccess(sourceAccount, {
                ["id"] = exports.data:getCharVar(data, "id"),
                ["name"] = exports.data:getCharVar(data, "firstname") .. " " .. exports.data:getCharVar(data, "lastname")
            })
        elseif action == "remove" then
            done = removeAccess(sourceAccount, data)
        elseif action == "check" then 
            done = isInAccessList(data, sourceAccount)
        end
        TriggerClientEvent("bank:access", _source, action, done)
    end
)

RegisterServerEvent("bank:createcard")
AddEventHandler(
    "bank:createcard",
    function(sourceAccount, code)
        local _source, card, done = source, 0, "maxCards"
        card, done = addCard(sourceAccount, code)
    
        exports.inventory:addPlayerItem(_source, "bankcard", 1, {
            label = 'Číslo karty: ' .. card, 
            id = card,
            account = sourceAccount
        })

        TriggerClientEvent("bank:createcard", _source, done)
    end
)

RegisterServerEvent("bank:blockcard")
AddEventHandler(
    "bank:blockcard",
    function(sourceAccount, cardId, action)
        local _source = source 
        local done = blockCard(sourceAccount, cardId, action)

        TriggerClientEvent("bank:blockcard", _source, cardId, done)
    end
)

RegisterServerEvent("bank:setinvoicepaid")
AddEventHandler(
    "bank:setinvoicepaid",
    function(sourceAccount, invoiceId)
        local _source = source 
        local done = exports.invoices:setInvoicePaid(invoiceId, true)

        TriggerClientEvent("bank:setinvoicepaid", _source, invoiceId, done)
    end
)

RegisterServerEvent("bank:payInvoice")
AddEventHandler(
    "bank:payInvoice",
    function(invoiceId, price)
        local _source = source 
        local done = "notEnoughMoney"
        local hasEnough = exports.inventory:checkPlayerItem(_source, "cash", price, {})
        local invoices = nil 
        if hasEnough then 
            done = exports.invoices:setInvoicePaid(invoiceId, true)
            if done == "done" then 
                exports.inventory:removePlayerItem(_source, "cash", price, {})

                invoices = exports.invoices:getInvoiceList("owner", exports.data:getCharVar(_source, "id"), 0)
            end
        end

        TriggerClientEvent("bank:setinvoicepaid", _source, invoiceId, done, invoices)
    end
)
RegisterServerEvent("bank:renamecard")
AddEventHandler(
    "bank:renamecard",
    function(sourceAccount, cardId, name)
        local _source = source 
        local done = renameCard(sourceAccount, cardId, name)

        TriggerClientEvent("bank:renamecard", _source, cardId, done)
    end
)

RegisterServerEvent("bank:deletecard")
AddEventHandler(
    "bank:deletecard",
    function(sourceAccount, cardId)
        local _source = source 
        local done = removeCard(sourceAccount, cardId)

        TriggerClientEvent("bank:deletecard", _source, cardId, done)
    end
)

RegisterServerEvent("bank:setpermissions")
AddEventHandler(
    "bank:setpermissions",
    function(sourceAccount, charId, data)
        local _source = source 
        local done = setPerms(sourceAccount, charId, data)
    end
)

--[[EXPORTS]]

-- GET/CHECK
function doesAccountExist(bankAccount)
    return accounts[bankAccount] ~= nil
end

function getAccountVar(bankAccount, var)
    return accounts[bankAccount][var]
end

function getAccount(bankAccount)
    return accounts[bankAccount]
end

function getAccounts()
    return accounts
end

function getAccessableAccounts(charId, jobName, jobGrade, inKey, addInvoices, addPersonalInvoices, addFines)
    local accessedAccounts, counted = {}, 0
    for key, value in pairs(accounts) do
        if accounts[key].founder.id == charId or (jobName == accounts[key].access_list["job"]["name"] and accounts[key].access_list["job"]["grade"] <= jobGrade) or isInAccessList(charId, key) then
            if inKey then 
                accessedAccounts[key] = accounts[key]
                if addInvoices then 
                    accessedAccounts[key].invoices = exports.invoices:getInvoiceList("bank", key)
                end
            else 
                table.insert(accessedAccounts, accounts[key])
            end
            counted = counted + 1
        end
    end
    if addPersonalInvoices then 
        accessedAccounts.personalinvoices = exports.invoices:getInvoiceList("owner", charId, 0)
    end
    if addFines then 
        accessedAccounts.fines = exports.fines:getFineList(charId)
    end
    return accessedAccounts, counted
end

function isAccessableAccount(bankAccount, charId, jobName, jobGrade)
    if accounts[bankAccount].founder.id == charId or (jobName == accounts[bankAccount].access_list["job"]["name"] and accounts[bankAccount].access_list["job"]["grade"] <= jobGrade) or isInAccessList(charId, bankAccount) then
        return true 
    end
    return false
end

function getAccountJob(bankAccount)
    if accounts[bankAccount] ~= nil then 
        return accounts[bankAccount].access_list.job.name 
    end
    return nil  
end

function isInAccessList(charId, bankAccount)
    local currentAccessList = accounts[bankAccount]["access_list"]["users"]
    for i = 1, #currentAccessList do
        if charId == currentAccessList[i]["id"] then
            return true
        end
    end
    return false
end

-- SET
function create(founder, balance, type, number, description, access_list)
    if founder == nil then 
        return "missingVariables" 
    end

    if balance == nil or balance < 0 then 
        balance = 0
    end

    local try = 0 
    number = generateAccountNumber(tostring(number))
    while accounts[number] ~= nil do 
        number = generateAccountNumber(tostring(number))
        Citizen.Wait(50)
        try = try + 1

        if try > 20 then 
            return "looped" 
        end
    end

    if description == nil then 
        description = "NEPOJMENOVANÝ BANKOVNÍ ÚČET"
    end

    if access_list == nil then 
        if type == nil or type.type == "personal" then 
            access_list = {
                ["job"] = {
                    ["name"] = "none",
                    ["grade"] = 1
                },
                ["users"] = {}
            }
        else 
            access_list = {
                ["job"] = {
                    ["name"] = type.job,
                    ["grade"] = type.grade
                },
                ["users"] = {}
            }
        end
    end

    MySQL.Async.execute(
        "INSERT INTO bank_accounts (number, description, founder, access_list, standing_orders, contacts, cards, balance) VALUES (@number, @description, @founder, @access_list, '[]', '[]', '[]', @balance)",
        {
            ["@number"] = number,
            ["@description"] = description,
            ["@founder"] = json.encode(founder),
            ["@access_list"] = json.encode(access_list),
            ["@balance"] = balance
        },
        function()
            accounts[number] = {
                number = number,
                description = description,
                founder = founder,
                access_list = access_list,
                balance = balance,
                changed = false
            }
            return "done"
        end
    )   
    return "done"
end

function generateAccountNumber(part1)
    local creatednumber = part1.sub(part1, 1, 2)
    local length = 10 - creatednumber.len(creatednumber)

    while length > 0 do 
        local randomnumber = tostring(math.random(10, 99))
        creatednumber = creatednumber .. randomnumber
        length = length - randomnumber.len(randomnumber)
    end

    return creatednumber
end

function delete(sourceAccount)
    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end
    
    MySQL.Async.execute(
        "DELETE FROM bank_accounts WHERE number=@number",
        {
            ["@number"] = sourceAccount
        },
        function()
            accounts[sourceAccount] = nil
            return "done"
        end
    )   
    return "done"
end

function withdraw(source, sourceAccount, value, actionType, save)
    if sourceAccount == nil or value == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    if type(value) ~= "number" then 
        value = tonumber(value)
    end

    if value <= 0 then 
        return "negativeValue"
    end

    if actionType == "take" then 
        if accounts[sourceAccount].balance >= value then 
            local result = exports.inventory:addPlayerItem(source, "cash", value, {})
            if result ~= "done" then 
                return result
            end
            accounts[sourceAccount].balance = accounts[sourceAccount].balance - value 
        else return "noFunds" end 
    elseif actionType == "put" then 
        if exports.inventory:checkPlayerItem(source, "cash", value, {}) then 
            accounts[sourceAccount].balance = accounts[sourceAccount].balance + value 
            exports.inventory:removePlayerItem(source, "cash", value, {})
        else return "noCash" end 
    else
        return "wrongType"
    end

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function addFunds(sourceAccount, value, save)
    if sourceAccount == nil or value == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    if type(value) ~= "number" then 
        value = tonumber(value)
    end

    if value <= 0 then 
        return "negativeValue"
    end

    accounts[sourceAccount].balance = accounts[sourceAccount].balance + value 

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function checkFunds(sourceAccount, value, remove, save)
    if sourceAccount == nil or value == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end
    
    if type(value) ~= "number" then 
        value = tonumber(value)
    end

    if value <= 0 then 
        return "negativeValue"
    end

    if accounts[sourceAccount].balance < value then 
        return "missingFunds"
    end

    if remove then 
        accounts[sourceAccount].balance = accounts[sourceAccount].balance - value 
    end

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    if remove then 
        TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    end
    return "done"
end

function removeFunds(sourceAccount, value, save)
    if sourceAccount == nil or value == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    if type(value) ~= "number" then 
        value = tonumber(value)
    end

    if value <= 0 then 
        return "negativeValue"
    end

    accounts[sourceAccount].balance = accounts[sourceAccount].balance - value 

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function transferFunds(sourceAccount, targetAccount, value, save)
    if sourceAccount == nil or value == nil or targetAccount == nil then 
        return "missingVariable"
    end

    if targetAccount == sourceAccount then 
        return "sameAccount"
    end

    if accounts[sourceAccount] == nil then 
        return "missingSourceAccount"
    end

    if accounts[targetAccount] == nil then 
        return "missingTargetAccount"
    end

    if type(value) ~= "number" then 
        value = tonumber(value)
    end

    if value <= 0 then 
        return "negativeValue"
    end

    if accounts[sourceAccount].balance < value then 
        return "missingFunds"
    end

    accounts[sourceAccount].balance = accounts[sourceAccount].balance - value 
    accounts[targetAccount].balance = accounts[targetAccount].balance + value 

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[sourceAccount].balance,
                ["number"] = sourceAccount
            }
        )

        MySQL.Async.execute(
            "UPDATE bank_accounts SET balance=@balance WHERE number = @number",
            {
                ["balance"] = accounts[targetAccount].balance,
                ["number"] = targetAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)

        accounts[targetAccount].changed = true 
        table.insert(accountsToSave, targetAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    TriggerClientEvent("bank:sync", -1, accounts[targetAccount])
    return "done"
end

function renameAccount(sourceAccount, value, save)
    if sourceAccount == nil or value == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    if type(value) ~= "string" then 
        value = tostring(value)
    end

    if value == "" then 
        return "emptyValue"
    end

    accounts[sourceAccount].description = value 

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET description=@description WHERE number = @number",
            {
                ["description"] = value,
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function addAccess(sourceAccount, data, save)
    if sourceAccount == nil or data == nil or data.id == nil or data.name == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    if accounts[sourceAccount].founder.id == data.id then 
        return "isOwner"
    end

    for i=1, #accounts[sourceAccount].access_list.users do 
        if accounts[sourceAccount].access_list.users[i].id == data.id then 
            return "hasAccess"
        end
    end

    table.insert(accounts[sourceAccount].access_list.users, {
        name = data.name,
        id = data.id,
        permissions = {
            ["balance"] = true,
            ["withdraw-take"] = true,
            ["withdraw-put"] = true,
            ["transfer"] = true,
            ["changetype"] = false,
            ["changeowner"] = false,
            ["changename"] = false,
            ["access"] = false,
            ["invoices"] = true,
            ["payinvoice"] = false
        }
    })

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET access_list=@access_list WHERE number = @number",
            {
                ["access_list"] = json.encode(accounts[sourceAccount].access_list),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function removeAccess(sourceAccount, charId, save)
    if sourceAccount == nil or charId == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    local index = nil 
    for i=1, #accounts[sourceAccount].access_list.users do 
        if accounts[sourceAccount].access_list.users[i].id == charId then 
            index = i
            break
        end
    end

    if index == nil then 
        return "noAccess"
    end

    table.remove(accounts[sourceAccount].access_list.users, index)

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET access_list=@access_list WHERE number = @number",
            {
                ["access_list"] = json.encode(accounts[sourceAccount].access_list),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function changeType(sourceAccount, type, data, save)
    if sourceAccount == nil or type == nil or (type == "company" and data == nil) then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end 

    if type == "company" then 
        accounts[sourceAccount].access_list.job = data 
    elseif type == "personal" then
        accounts[sourceAccount].access_list.job = {
            ["name"] = "none",
            ["grade"] = 1
        }
    else
        return "wrongType"
    end

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET access_list=@access_list WHERE number = @number",
            {
                ["access_list"] = json.encode(accounts[sourceAccount].access_list),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function changeOwner(sourceAccount, data, save)
    if sourceAccount == nil or data == nil or data.id == nil or data.name == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end 

    accounts[sourceAccount].founder = data 

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET founder=@founder WHERE number = @number",
            {
                ["founder"] = json.encode(accounts[sourceAccount].founder),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function setPerms(sourceAccount, charId, data, save)
    if sourceAccount == nil or charId == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    local index = nil 
    for i=1, #accounts[sourceAccount].access_list.users do 
        if accounts[sourceAccount].access_list.users[i].id == charId then 
            index = i
            break
        end
    end

    if index == nil then 
        return "noAccess"
    end

    if data == nil or data == "default" then 
        accounts[sourceAccount].access_list.users[index].permissions = Config.defaultPerms
    elseif type(data) == "table" then 
        for key,value in pairs(data) do
            accounts[sourceAccount].access_list.users[index].permissions[key] = value
        end
    end
    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET access_list=@access_list WHERE number = @number",
            {
                ["access_list"] = json.encode(accounts[sourceAccount].access_list),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function addCard(sourceAccount, code, save)
    if sourceAccount == nil then 
        return 0, "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return 0, "missingAccount"
    end

    if #accounts[sourceAccount].cards > Config.maxCards then 
        return 0, "maxCards"
    end

    if code == nil then 
        code = generateActivationCardCode()
    end

    local cardKey = generateCardKey()

    accounts[sourceAccount].cards[cardKey] = {
        id = cardKey,
        code = code,
        description = "Platební karta",
        perms = {
            ["put"] = true,
            ["take"] = true,
            ["balance"] = true
        },
        lastTaken = 0,
        blocked = 0
    }

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET cards=@cards WHERE number = @number",
            {
                ["cards"] = json.encode(accounts[sourceAccount].cards),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return cardKey, "done"
end

function generateActivationCardCode()
    return math.random(10000000, 99999999)  
end

function generateCardKey()
    local id = ""
    for i=1, 20 do 
        id = id .. Config.idChars[math.random(#Config.idChars)]
    end

    return id 
end

function removeCard(sourceAccount, cardId, save)
    if sourceAccount == nil or cardId == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    if accounts[sourceAccount].cards[cardId] == nil then 
        return "missingCard"
    end

    accounts[sourceAccount].cards[cardId] = nil 

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET cards=@cards WHERE number = @number",
            {
                ["cards"] = json.encode(accounts[sourceAccount].cards),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end

function blockCard(sourceAccount, cardId, action, save)
    if sourceAccount == nil or cardId == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    if accounts[sourceAccount].cards[cardId] == nil then 
        return "missingCard"
    end

    local done = "done"
    if action == "block" then 
        accounts[sourceAccount].cards[cardId].blocked = os.time()
        accounts[sourceAccount].cards[cardId].blockedLabel = os.date("%X %x", os.time()) 
        done = "blocked"
    else 
        accounts[sourceAccount].cards[cardId].blocked = 0
        accounts[sourceAccount].cards[cardId].blockedLabel = nil 
        done = "unblocked"
    end
     

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET cards=@cards WHERE number = @number",
            {
                ["cards"] = json.encode(accounts[sourceAccount].cards),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return done
end

function renameCard(sourceAccount, cardId, name, save)
    if sourceAccount == nil or cardId == nil then 
        return "missingVariable"
    end

    if accounts[sourceAccount] == nil then 
        return "missingAccount"
    end

    if accounts[sourceAccount].cards[cardId] == nil then 
        return "missingCard"
    end

    accounts[sourceAccount].cards[cardId].description = name

    if save then 
        MySQL.Async.execute(
            "UPDATE bank_accounts SET cards=@cards WHERE number = @number",
            {
                ["cards"] = json.encode(accounts[sourceAccount].cards),
                ["number"] = sourceAccount
            }
        )
    else
        accounts[sourceAccount].changed = true 
        table.insert(accountsToSave, sourceAccount)
    end

    TriggerClientEvent("bank:sync", -1, accounts[sourceAccount])
    return "done"
end