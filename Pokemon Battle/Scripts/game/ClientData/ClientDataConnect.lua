local _M = ClientData

-- connect/disconnect, msg/error

function _M.onConnectedAndAuthorized()
    lc.log("[NETWORK] ClientData.onConnectedAndAuthorized")

    _M._socketStatus = _M.SocketStatus.connected

    _M._sentHeartbeatTimestamp = nil
    _M._receivedHeartbeatTimestamp = nil
    if _M._heartbeatGapNoticeId ~= nil then
        NoticeManager.hide(_M._heartbeatGapNoticeId)
        _M._heartbeatLostNoticeId = nil
    end
    if _M._heartbeatLostNoticeId ~= nil then
        NoticeManager.hide(_M._heartbeatLostNoticeId)
        _M._heartbeatLostNoticeId = nil
    end

    _M._schedulerHearBeatID = lc.Scheduler:scheduleScriptFunc(function(dt)    
        _M.sendHeartBeat()
    end, 1, false)
    
    _M.loadUserRegion()
    if _M.hasUserRegion() then
        _M.loginGameServer()
    else
        _M.loginRegionServer()
    end
end

function _M.onConnectFail()
    lc.log("[NETWORK] ClientData.onConnectFail")
end

function _M.onDisconnect()
    print ("[NETWORK] ClientData.onDisconnect")

    _M._socketStatus = _M.SocketStatus.disconnected

    _M._sentHeartbeatTimestamp = nil
    _M._receivedHeartbeatTimestamp = nil
    if _M._schedulerHearBeatID ~= nil then
        lc.Scheduler:unscheduleScriptEntry(_M._schedulerHearBeatID)
        _M._schedulerHearBeatID = nil        
    end

    if _M._socketDataListener ~= nil then
        lc.Dispatcher:removeEventListener(_M._socketDataListener)
        _M._socketDataListener = nil
    end

    if P then
        P:stopPlayerScheduler()
    end
end

function _M.onSocketData(event)
    if event._socket ~= _M._socket then return false end

    local hasError = event._hasError
    if not hasError then
        return _M.onMsg(event._msg)
    else
        return _M.onError(event._msg)
    end
end

function _M.loginGameServer()
    local userId = _M.DEBUG_USER_ID
    if userId == nil or userId == 0 then
        _M.sendUserRegister()
    else
        _M.sendUserLogin(userId)
    end
end

function _M.loginRegionServer()
    _M.sendRegionListReq()
end

function _M.loadPlayerData(player, resp)
    player:clear()

    _M._baseTime = lc.Director:getCurrentTime()
    player:init(resp)
end

function _M.reconnectRegionServer()
    _M.disconnect(false)
    local regionServer = lc.App:getRegionServer()
    local parts = string.splitByChar(regionServer, ':')
    _M.connect(parts[#parts - 1], parts[#parts])
end

function _M.reconnectGameServer()
    _M._isWorking = true
    _M.loadUserRegion()
    
    _M.disconnect(false)
    _M.connect(_M._userRegion._ip, _M._userRegion._port)
end

function _M.connect(ip, port)
    lc.log("[NETWORK] ClientData.connect %s %d", ip, port)

    local Socket_pb = require "Socket_pb"
    _M._socket = Socket_pb.new(ip, port)
    if _M._socketDataListener == nil then
        _M._socketDataListener = lc.addEventListener(Socket_pb.Event.data, function(event) _M.onSocketData(event) end)
        table.insert(_M._evtListeners, _M._socketDataListener)
    end
    _M._socket:connect()
end

function _M.disconnect(isSendEvent)
    lc.log("[NETWORK] ClientData.disconnect %s", isSendEvent and "true" or "false")

    if _M._socket ~= nil then
        _M._socket:disconnect(isSendEvent)
        _M._socket:close(isSendEvent)
        _M._socket = nil
    end

    if not isSendEvent then
        _M.onDisconnect()
    end
end