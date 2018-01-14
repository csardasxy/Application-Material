local _M = {}

local BATTLE_TEST_FILE_PREFIX     = "bt_"

_M.OperationType = {
    _empty          = "empty",
    _export         = "export",
    _modifyHp       = "modify_hp",
    _batch          = "batch",
    _runTest        = "run_test",
    _load           = "load"
}

_M._curOpType = _M.OperationType._empty

_M._batch = {
    _batchCount     = 0,
    _okCount        = 0,
    _errorCount     = 0,
    _curBatch       = 1,
    _callback       = nil,
    _filenames      = nil,
}

_M._singleFileName = nil
_M._playerUsedCards = {}
_M._opponentUsedCards = {}

_M.DEFAULT_FILE = lc.File:getWritablePath()..'DEFAULT_TEST_CARDS.ygo'

function _M.importBattleTestData(filename)
    local tmpFilename = _M._singleFileName
    if filename ~= nil and filename ~= "" then
        _M._singleFileName = filename
    end
    local battleData = nil
    if _M._singleFileName ~= nil and _M._singleFileName ~= ""  then

        lc.log("filename is " .. _M._singleFileName)
        local content = lc.readFile(_M._singleFileName)
        lc.log("content is " .. content)
        battleData = json.decode(content)

    else
        lc.log("filename null")
    end

    if filename ~= nil and filename ~= "" then
        _M._singleFileName = tmpFilename
    end
    return battleData
end

function _M.parseInfoIds(data)
    local battleTable = {
        AttackerFields = {},
        DefenderFields = {}
    }

    battleTable.AttackerFields.P = BattleTestData.insertFilterCard(data.AttackerFields.P)
    battleTable.AttackerFields.H = BattleTestData.insertFilterCard(data.AttackerFields.H)
    battleTable.AttackerFields.B = BattleTestData.insertFilterCard(data.AttackerFields.B)
    battleTable.AttackerFields.G = BattleTestData.insertFilterCard(data.AttackerFields.G)
    battleTable.AttackerFields.S = BattleTestData.insertFilterCard(data.AttackerFields.S)
    battleTable.AttackerFields.R = BattleTestData.insertFilterCard(data.AttackerFields.R)

    battleTable.DefenderFields.P = BattleTestData.insertFilterCard(data.DefenderFields.P)
    battleTable.DefenderFields.H = BattleTestData.insertFilterCard(data.DefenderFields.H)
    battleTable.DefenderFields.B = BattleTestData.insertFilterCard(data.DefenderFields.B)
    battleTable.DefenderFields.G = BattleTestData.insertFilterCard(data.DefenderFields.G)
    battleTable.DefenderFields.S = BattleTestData.insertFilterCard(data.DefenderFields.S)
    battleTable.DefenderFields.R = BattleTestData.insertFilterCard(data.DefenderFields.R)

    return battleTable
end

function _M.exportTestCardsData(filename, table)
    if filename ~= nil then
        BattleTestData.onFileSaved(filename, table)     
    end
end

function _M.exportToBattleLog()
    
    if _M._singleFileName ~= nil and _M._singleFileName ~= ""  then
        local revFilename = string.reverse(_M._singleFileName)
        local index= string.find(revFilename, "[.]")
        local logName = string.sub(_M._singleFileName, 1, #_M._singleFileName - index) .. ".log"
        lc.writeFile(logName, ClientData._battleDebugLog)
    end
    
end

function _M.exportUsedCards()
    if _M._singleFileName ~= nil and _M._singleFileName ~= "" and (#_M._playerUsedCards > 0 or #_M._opponentUsedCards > 0)  then
        local battleTable = _M.importBattleTestData()
        battleTable.AttackerUsedCards = _M._playerUsedCards
        battleTable.DefenderUsedCards = _M._opponentUsedCards
        local str = json.encode(battleTable)
        if str ~= "" then
            lc.writeFile(_M._singleFileName, str)
        end
    end
end

function _M.onFileSaved(fileName, table)
    local battleData = {
        AttackerFields = {},
        DefenderFields = {}
    }

    battleData.AttackerFields.HP = table.attackerHP
    battleData.AttackerFields.P = BattleTestData.filterCardId(table.attackerP, "P")
    battleData.AttackerFields.H = BattleTestData.filterCardId(table.attackerH, "H")
    battleData.AttackerFields.B = BattleTestData.filterCardId(table.attackerB, "B")
    battleData.AttackerFields.G = BattleTestData.filterCardId(table.attackerG, "G")
    battleData.AttackerFields.S = BattleTestData.filterCardId(table.attackerS, "S")
    battleData.AttackerFields.R = BattleTestData.filterCardId(table.attackerR, "R")
    battleData.DefenderFields.HP = table.defenderHP
    battleData.DefenderFields.P = BattleTestData.filterCardId(table.defenderP, "P")
    battleData.DefenderFields.H = BattleTestData.filterCardId(table.defenderH, "H")
    battleData.DefenderFields.B = BattleTestData.filterCardId(table.defenderB, "B")
    battleData.DefenderFields.G = BattleTestData.filterCardId(table.defenderG, "G")
    battleData.DefenderFields.S = BattleTestData.filterCardId(table.defenderS, "S")
    battleData.DefenderFields.R = BattleTestData.filterCardId(table.defenderR, "R")

    local str = json.encode(battleData)

    lc.log(str)
    lc.writeFile(fileName, str)
end

function _M.getCurDateTime()
    local orgDateTime = os.date()
    local M = string.sub(orgDateTime, 1, 2)
    local D = string.sub(orgDateTime, 4, 5)
    local Y = string.sub(orgDateTime, 7, 8)

    local h = string.sub(orgDateTime, 10, 11)
    local m = string.sub(orgDateTime, 13,  14)
    local s = string.sub(orgDateTime, 16, 17)

--    return Y .. "-" .. M .. "-" .. D .. "_" .. h .. "-" .. m .. "-" .. s
    return Y .. "-" .. M .. "-" .. D
end

function _M.filterCardId(cards, flag)
    local ids = {}
    
    if cards == nil or type(cards) ~= "table" then return nil end

    if flag == "P" or flag == "H" or flag == "G" or flag == "R" then
        for k, card in ipairs(cards)  do
            lc.log("llllllll--"..card._id)
--            local info = {}
--            info._index = k
            table.insert(ids, card._infoId)
        end
    elseif flag == "B" then
        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
            if cards[i] then
                local id = cards[i]._infoId
                table.insert(ids, id)
            else
                table.insert(ids, 0)
            end
        end
    elseif flag == "S" then
        for i = 1, Data.MAX_CARD_COUNT_ON_COVER do
            if cards[i] then
                local id = cards[i]._infoId
                table.insert(ids, id)
            else
                table.insert(ids, 0)
            end
        end
    end
    return ids
end

function _M.resetUsedCards()
    _M._playerUsedCards = {}
    _M._opponentUsedCards = {}
end

function _M.dealTestResult()

    if BattleTestData._curOpType == _M.OperationType._runTest then
        require("Dialog").showDialog(
            _M.isTestResultSame() and 'PASS' or 'FAIL', function() 
        end)
    elseif BattleTestData._curOpType == _M.OperationType._batch then
        if _M.isTestResultSame() then
            _M._batch._okCount = _M._batch._okCount + 1
        else
            _M._batch._errorCount = _M._batch._errorCount + 1
        end

        if _M._batch._callback and _M._batch._curBatch < _M._batch._batchCount then
            _M._batch._curBatch = _M._batch._curBatch + 1
            _M._batch._callback()
        else
            BattleTestData._batch._filenames = nil
            _M._batch._callback()
            _M.resetBatch()
            BattleTestData._singleFileName = nil
            ToastManager.push(Str(STR.BATCH_END), 1.0)
        end
    end
end

function _M.resetBatch()
    _M._curOpType = _M.OperationType._empty
    _M._batch._batchCount = 0
    _M._batch._curBatch = 1
    _M._batch._okCount = 0
    _M._batch._errorCount = 0
    _M._batch._callback = nil
    _M._batch._filenames = nil
end

function _M.isTestResultSame()
    if _M._singleFileName == nil or _M._singleFileName == "" then return false end
    local battleTable = _M.importBattleTestData()

    
    local revFilename = string.reverse(_M._singleFileName)
    print(revFilename)
    local index= string.find(revFilename, "[.]")

    local orgLogFileName = string.sub(_M._singleFileName, 1, #_M._singleFileName - index) .. ".log"
    local testLogFileName = string.sub(_M._singleFileName, 1, #_M._singleFileName - index) .. "_" .. _M.getCurDateTime() .. ".log"
    local testBattleLog = ClientData._battleDebugLog

    local result = _M.fileContentContains(testBattleLog, orgLogFileName, testLogFileName)

    print("isTestResultSame is ", result)
    return result
end

-- judge whether file1 content contains the content of file2
function _M.fileContentContains(log, name2, saveName)
    local file2 = io.open(name2, "r")

    if not file2 then return false end

    local logs = _M.splitString(log, "\n")
    local lines1 = {}
    local lines2 = {}
    local canStart1, canStart2 = false, false
    
    for i = 1, #logs do
        local line = logs[i]
        if canStart1 or line == "[BATTLE] ==================================" then
            canStart1 = true
            table.insert(lines1, line)
        end
    end

    for line in file2:lines() do
        if canStart2 or line == "[BATTLE] ==================================" then
            canStart2 = true
            table.insert(lines2, line)
        end
    end

    file2:close()

    for i = 2, #lines2 do
        if lines1[i] ~= lines2[i] then
            lc.writeFile(saveName, log)

            return false
        end
    end
    return true
end

function _M.splitString(str, spl)
    local strs = {}
    while true do
        local index = string.find(str, spl)
        if index then
            local item = string.sub(str, 1, index - 1)
            table.insert(strs, item)
            str = string.sub(str, index + 1)
        else
            break
        end
    end
    
    return strs
end

BattleTestData = _M
