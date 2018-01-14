local _M = class("Socket_pb")

local SOCKET_TICK_TIME = 0.1 			-- check socket data interval
local SOCKET_CONNECT_FAIL_TIMEOUT = 10	-- socket failure timeout

_M.Status = 
{
    closed              = "closed",
    not_connected       = "Socket is not connected",
    already_connected   = "already connected",
    already_in_progress = "Operation already in progress",
    timeout             = "timeout",   
}

_M.Event = 
{
    connect             = "SOCKET_PB_CONNECT",           -- _status = str
    connect_fail        = "SOCKET_PB_CONNECT_FAIL",      -- _status = str
    data                = "SOCKET_PB_DATA",              -- _hasError = bool, _msg = ProtoMsg
    disconnect          = "SOCKET_PB_DISCONNECT",
}

local _socket = require "socket"
local _scheduler = lc.Scheduler
local _dispacher

_M._VERSION = _socket._VERSION
_M._DEBUG = _socket._DEBUG

function _M:ctor(host, port)
    self._host = host
    self._port = port
    self._isConnected = false
    
    self._name = host..":"..port
	self._recvScheduler = nil			   -- timer for recv
	self._connectTimeTickScheduler = nil   -- timer for connect timeout
	self._tcp = nil
	
	self:_resetRecvBuf()
	self._sSerial = 0
	self._sStep = 0
	self._cSerial = 0
	self._cStep = 0
end

function _M:setName(name)
    self._name = name
end

function _M:setTickTime(time)
	SOCKET_TICK_TIME = time
	return self
end

function _M:setConnFailTime(time)
	SOCKET_CONNECT_FAIL_TIMEOUT = time
	return self
end

function _M.getTime()
    return _socket.gettime()
end

function _M:connect(host, port)
	if host then self._host = host end
	if port then self._port = port end
	
	assert(self._host or self._port, "Host and port are necessary!")
	lc.log("[NETWORK] %s connect", self._name)

	local isIpv6Only = false
    local addrinfo, err = _socket.dns.getaddrinfo(self._host)
    if addrinfo ~= nil then
        for k, v in pairs(addrinfo) do
            lc.log("[NETWORK] %s family: %s", self._name, v.family)
            if v.family == 'inet6' then
                isIpv6Only = true
                break
            end
        end
    end

    if isIpv6Only then
        self._tcp = _socket.tcp6()
    else
        self._tcp = _socket.tcp()
    end
    if self._tcp == nil then 
        self:_onConnectFail() 
        return
    end
    self._tcp:settimeout(0)

	local connectTimeTick = function ()
	    lc.log("[NETWORK] %s connectTimeTick", self._name)
		if self:_connect() then
            self:_onConnected()
        else
            self._waitConnect = self._waitConnect or 0
            self._waitConnect = self._waitConnect + SOCKET_TICK_TIME
            if self._waitConnect >= SOCKET_CONNECT_FAIL_TIMEOUT then
                self._waitConnect = nil
                self:close()
                self:_onConnectFail()
            end
        end
	end
	self._connectTimeTickScheduler = _scheduler:scheduleScriptFunc(connectTimeTick, SOCKET_TICK_TIME, false)
end

function _M:disconnect(isSendEvent)
    self:_disconnect(isSendEvent)
end

function _M:close()
    lc.log("[NETWORK] %s close", self._name)
	self._tcp:close()
	if self._connectTimeTickScheduler then 
	   _scheduler:unscheduleScriptEntry(self._connectTimeTickScheduler) 
	   self._connectTimeTickScheduler = nil
	end
	if self._recvScheduler then 
	   _scheduler:unscheduleScriptEntry(self._recvScheduler)
	   self._recvScheduler = nil 
	end
end

function _M:sendProtoMsg(msg)
    if not self._isConnected then return end

    local data = msg:SerializeToString()
    
    -- Calc encrypted len
    local encryptLen = #data + 2
       
    --Calc crc16 and add to the last bytes
    local crc16 = string.crc16(data)
    data = data..string.pack(">H", crc16)
    
    --Encrypt data except 'len' field
    self._cSerial = bit.band(self._cSerial + self._cStep, 0xFFFFFFFF)
    data = string.encrypt(data, self._cSerial)

    if self:_send(string.pack(">I", encryptLen)..data) == nil then
        self:disconnect(true)
        self:close()
    end
end

--------------------
-- private
--------------------

function _M:_connect()
	local succ, status = self._tcp:connect(self._host, self._port)
	return succ == 1 or status == _M.Status.already_connected
end

function _M:_disconnect(isSendEvent)
    assert(isSendEvent ~= nil, "on disconnect isSendEvent can not be nil")

    if not self._isConnected then return end
    
	self._isConnected = false
	self._tcp:shutdown()

	if isSendEvent then
	   local eventCustom = cc.EventCustom:new(_M.Event.disconnect)
	   eventCustom._socket = self
       lc.Dispatcher:dispatchEvent(eventCustom)
	end
end

function _M:_onConnected()
	lc.log("[NETWORK] %s _onConnected", self._name)
	self._isConnected = true
	
	if self._connectTimeTickScheduler then _scheduler:unscheduleScriptEntry(self._connectTimeTickScheduler) end
	
	local eventCustom = cc.EventCustom:new(_M.Event.connect)
	eventCustom._socket = self
	lc.Dispatcher:dispatchEvent(eventCustom)
	
	self:_resetRecvBuf()

    local recv = function()
        while true do
            local body, status, partial = self._tcp:receive(self._remainBytes)	-- read the package body            
            if status == _M.Status.closed or status == _M.Status.not_connected then
                self:close()
                if self._isConnected then
                    self:_onDisconnect()
                else
                    self:_onConnectFail(status)
                end
                return
            end
	    	
	    	body = body or partial
            local recved = #body

            if recved > 0 then
                self._remainBytes = self._remainBytes - recved
                self._recvBuf = self._recvBuf..body
            end
            if self._remainBytes == 0 then
                if self._isRecvSize then
                    self._isRecvSize = false
                    local _, i = string.unpack(self._recvBuf, ">I")
                    self._remainBytes = i
                    self._recvBuf = "" 
                else
                    self:_processRecvBuf()
                end    
            end

	    	if status == _M.Status.timeout then return end
		end
	end

	-- start to read TCP data
	self._recvScheduler = _scheduler:scheduleScriptFunc(recv, SOCKET_TICK_TIME, false)
end

function _M:_onDisconnect()
    lc.log("[NETWORK] %s _onDisConnect", self._name)
    self._isConnected = false
    
    if self._connectTimeTickScheduler then _scheduler:unscheduleScriptEntry(self._connectTimeTickScheduler) end
    if self._recvScheduler then _scheduler:unscheduleScriptEntry(self._recvScheduler) end    
    
    local eventCustom = cc.EventCustom:new(_M.Event.disconnect)
    eventCustom._socket = self
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:_onConnectFail(status)
	lc.log("[NETWORK] %s _onConnectFail", self._name)

	local eventCustom = cc.EventCustom:new(_M.Event.connect_fail)
	eventCustom._status = status
	eventCustom._socket = self
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:_send(data)
    if not self._isConnected then
        local eventCustom = cc.EventCustom:new(_M.Event.disconnect)
        eventCustom._socket = self
        lc.Dispatcher:dispatchEvent(eventCustom)
        
        return
    end
    return self._tcp:send(data)
end

function _M:_resetRecvBuf()
    self._isRecvSize = true
    self._recvBuf = ""
    self._remainBytes = 4
end

function _M:_processRecvBuf()
    if self._sStep == 0 then
        lc.log("[NETWORK] %s send authentication", self._name)
    
        local respMsg = SglMsg_pb.SglRespMsg()
        respMsg:ParseFromString(self._recvBuf)
        local data = respMsg.Extensions[Auth_pb.SglAuthMsg.challenge] 
                
        self._sSerial = self:_unpackInt(data, 1)
        self._sStep = self:_unpackInt(data, 2)
        self._cSerial = self:_unpackInt(data, 3)
        self._cStep = self:_unpackInt(data, 4)
        
        local reqMsg = SglMsg_pb.SglReqMsg()
        reqMsg.type = SglMsgType_pb.PB_TYPE_AUTHENTICATION
        reqMsg.Extensions[Auth_pb.SglAuthMsg.authentication] = data
        self:sendProtoMsg(reqMsg)

        self:_resetRecvBuf()
    else
        self._sSerial = bit.band(self._sSerial + self._sStep, 0xFFFFFFFF)
        local data = string.decrypt(self._recvBuf, self._sSerial)
        local dataLen = #data
        local n, receviedCrc16 = string.unpack(string.sub(data, dataLen - 1), ">H")
        data = string.sub(data, 1, dataLen - 2)

        local crc16 = string.crc16(data)
        --lc.log("[NETWORK] %s recv bufLen:%d crc:%d, %s", self._name, #data, crc16, crc16 == receviedCrc16 and 'OK' or 'ERROR')

        local eventCustom = cc.EventCustom:new(_M.Event.data)
        if crc16 ~= receviedCrc16 then
            eventCustom._hasError = true 
        else
            local respMsg = SglMsg_pb.SglRespMsg()
            respMsg:ParseFromString(data)
            
            eventCustom._hasError = false
            eventCustom._msg = respMsg
        end
        eventCustom._socket = self

        self:_resetRecvBuf()

        lc.Dispatcher:dispatchEvent(eventCustom)
    end
end

function _M:_unpackInt(data, index)
    local b = string.byte(data, index)
    if b >= 128 then b = 0xFF - b + 1 end
    local p = bit.lshift(b % 16, 3)

    local len, v = string.unpack(string.sub(data, p + 1, p + 5), ">i")
    return v
end


return _M
