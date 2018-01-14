lc = lc or {}

local _M = {}

--[[--
Enumerations used in this module
--]]--

_M.State = 
{
    unloaded                = 0,
    idle                    = 1,
    playing                 = 2,
    paused                  = 3,
}

_M.Behavior = 
{
    music                   = 0,
    effect                  = 1,
}

_M.SwitchType = 
{
    yes_replay              = 0,
    yes_once                = 1,
    no                      = 2,
}

_M.PlayCondition = 
{
    play                    = 0,
    stop                    = 1,
    ignore                  = 2,    
}


-- Audio event
_M.EVENT_STOPPED            = "LC_AUDIO_STOPPED"

--[[--
Private variables and methods
--]]--

local _playingAudioList = {}
local _muteFlag = 0
local _engine = cc.SimpleAudioEngine:getInstance()
local _scheduler = lc.Scheduler

local function handleAudioStop(audioInfo)
    if (audioInfo.playingParams.isNotifyStop) then
        local event = cc.EventCustom:new(_M.EVENT_STOPPED)
        event.audioInfo = audioInfo
        lc.Dispatcher:dispatchEvent(event)
    end
    
    --lc.log("audio stop:%d", audioInfo.id)

    audioInfo.state = _M.State.idle
    _playingAudioList[audioInfo.id] = nil
end

--[[--
Load information of audios from specified configuration plist file, you can also set a name to identify audios in this file from others.

@param  #string fileName        audio info plist file name
@param  #string cfgName         name to identify the audios contained in this plist file. default "main"
--]]--
function _M.loadAudioConfig(fileName, cfgName)
    cfgName = cfgName or "main"
    
    -- Add new name to config table or create new config table if not exists
    if (not _M._configs) then
        _M._configs = {}
        _M._configs.count = 1
    else
        _M._configs.count = _M._configs.count + 1
    end
    
    -- Create empty table for the new audios info
    _M._configs[cfgName] = {}

    -- Parse plist info
    local map = cc.FileUtils:getInstance():getValueMapFromFile(fileName)
    local audios = map["audios"]
    for _, audio in ipairs(audios) do
        local fileName = audio["name"]
        if (not fileName:find("%.")) then
           fileName = fileName..".mp3"
        end
        
        _M.addAudio(fileName, audio["behavior"], audio["duration"], audio["group"], audio["loop"], audio["condition"], audio["switch"])
    end
end

--[[--
Add a single audio by specifying all parameters

@param  #string fileName        file name of the audio, maybe contains path
@param  #number behavior        audio behavior
@param  #number duration        audio duration
@param  #number group           audio group
@param  #boolean isLoop         whether audio is loop
@param  #number playCondition   audio play condition
@param  #number switch		    audio switch type
@param  #string cfgName         name to identify the audios contained in this plist file. default "main"
--]]--
function _M.addAudio(fileName, behavior, duration, group, isLoop, playCondition, switch, cfgName)
    cfgName = cfgName or "main"
    
    _M._configs[cfgName] = _M._configs[cfgName] or {}
    local infoList = _M._configs[cfgName]

    local info = {
       id = table.getn(infoList) + 1, 
       name = fileName,
       cfgName = cfgName,
       behavior = behavior or _M.Behavior.music,
       duration = duration or -1,
       group = group or -1,
       isLoop = (isLoop == true) or (isLoop == 1),
       playCondition = playCondition or _M.PlayCondition.play,
       switch = switch or _M.SwitchType.yes_once,
       state = _M.State.unloaded,
       playingParams = {}
    }

    info.scheduleForStop = function(self, delay)
        local params = self.playingParams
        if params.scheduleId then
            _scheduler:unscheduleScriptEntry(params.scheduleId)
        end

        params.scheduleId = _scheduler:scheduleScriptFunc(function()
            _scheduler:unscheduleScriptEntry(params.scheduleId)
            params.scheduleId = nil

            handleAudioStop(self)
        end, delay or self.duration, false)
    end
    
    table.insert(infoList, info)
    return info
end

--[[--
Preload an audio to the memory

@param  #number audioId         audio id
@param  #string cfgName         config name where the audio belongs. default "main"
--]]--
function _M.preloadAudio(audioId, cfgName)
    cfgName = cfgName or "main"
    assert(_M._configs[cfgName], string.format("[lc.Audio.preloadAudio] The info table '%s' is not exist!", cfgName))

    local info = _M._configs[cfgName][audioId]
    assert(info, string.format("[lc.Audio.preloadAudio] The audio id '%d' in table '%s' is not exist!", audioId, cfgName))
    
    if (info.state ~= _M.State.unloaded) then return end
    
    if (info.behavior == _M.Behavior.music) then
        _engine:preloadMusic(info.name)
    else
        _engine:preloadEffect(info.name);
    end
    
    info.state = _M.State.idle
end

--[[--
Unload an audio from the memory, stop it if playing

@param  #number audioId         audio id
@param  #string cfgName         config name where the audio belongs. default "main"
--]]--
function _M.unloadAudio(audioId, cfgName)
    cfgName = cfgName or "main"
    assert(_M._configs[cfgName], string.format("[lc.Audio.unloadAudio] The info table '%s' is not exist!", cfgName))

    local info = _M._configs[cfgName][audioId]
    assert(info, string.format("[lc.Audio.unloadAudio] The audio id '%d' in table '%s' is not exist!", audioId, cfgName))
    
    if (info.state == _M.State.unloaded) then return end
    if (info.state == _M.State.playing) then _M.stopAudio(audioId, cfgName) end
    
    if (info.behavior == _M.Behavior.music) then
        _engine:stopMusic(true)
    else
        _engine:unloadEffect(info.name);
    end
    
    info.state = _M.State.unloaded
end

--[[--
Play an audio by specified audio id

@param  #number audioId         audio id
@param  #boolean isNotifyStop	whether send stop event when audio is stopped. default "false"
@param  #string cfgName         config name where the audio belongs. default "main"
--]]--
function _M.playAudio(audioId, isNotifyStop, cfgName)
    cfgName = cfgName or "main"
    assert(_M._configs[cfgName], string.format("[lc.Audio.playAudio] The info table '%s' is not exist!", cfgName))

    local info = _M._configs[cfgName][audioId]
    assert(info, string.format("[lc.Audio.playAudio] The audio id '%d' in table '%s' is not exist!", audioId, cfgName))
    
    isNotifyStop = isNotifyStop or false
    
    -- Check whether to play the audio
    if (info.state == _M.State.playing) then
        local pcond = info.playCondition
        if (pcond == _M.PlayCondition.stop) then
            _M.stopAudio(audioId, cfgName)
        elseif (pcond == _M.PlayCondition.ignore) then
            return
        end
    end
    
    -- Stop other audios in the same group
    if (info.group >= 0) then
        local audiosInSameGroup = {} 
        for _, playingInfo in pairs(_playingAudioList) do
            if (playingInfo.group == info.group) then
                table.insert(audiosInSameGroup, playingInfo)
            end
        end

        for _, info in ipairs(audiosInSameGroup) do
            _M.stopAudio(info.id, info.cfgName)
        end
    end
    
    -- Check mute flag
    if (bit.band(_muteFlag, bit.lshift(1, info.behavior)) ~= 0) then
        if (info.switch == _M.SwitchType.yes_once) then return end
    end
    
    -- Play audio
    if (info.behavior == _M.Behavior.music) then
        _engine:playMusic(info.name, info.isLoop)
        info.playingParams.id = 0
    else
        info.playingParams.id = _engine:playEffect(info.name, info.isLoop)
    end
    
    info.playingParams.playTime = os.time()
    info.playingParams.duration = 0
    
    _playingAudioList[info.id] = info
    info.state = _M.State.playing
    
    -- Check mute flag
    if (bit.band(_muteFlag, bit.lshift(1, info.behavior)) ~= 0) then
        if (info.switch == _M.SwitchType.yes_replay) then 
            _M.pauseAudio(info.id, info.cfgName) 
        end
    end     
    
    -- Check stop using duration if not in loop mode
    if (not info.isLoop) then
        info.playingParams.isNotifyStop = isNotifyStop
        info:scheduleForStop()
    end
end

--[[--
Pause an audio by specified audio id

@param  #number audioId         audio id
@param  #string cfgName         config name where the audio belongs. default "main"
--]]--
function _M.pauseAudio(audioId, cfgName)
    cfgName = cfgName or "main"
    assert(_M._configs[cfgName], string.format("[lc.Audio.pauseAudio] The info table '%s' is not exist!", cfgName))

    local info = _M._configs[cfgName][audioId]
    assert(info, string.format("[lc.Audio.pauseAudio] The audio id '%d' in table '%s' is not exist!", audioId, cfgName))
    
    if (info.state ~= _M.State.playing) then return end
   
    if (info.behavior == _M.Behavior.music) then
        _engine:pauseMusic()
    else
        _engine:pauseEffect(info.playingId)
    end
    
    info.state = _M.State.paused
    
    -- Update params if stop handler is scheduled
    local params = info.playingParams
    if (params.scheduleId) then
        _scheduler:unscheduleScriptEntry(params.scheduleId)
        params.scheduleId = nil
        params.duration = os.time() - params.playTime
    end
end

--[[--
Resume an audio by specified audio id

@param  #number audioId         audio id
@param  #string cfgName         config name where the audio belongs. default "main"
--]]--
function _M.resumeAudio(audioId, cfgName)
    cfgName = cfgName or "main"
    assert(_M._configs[cfgName], string.format("[lc.Audio.resumeAudio] The info table '%s' is not exist!", cfgName))

    local info = _M._configs[cfgName][audioId]
    assert(info, string.format("[lc.Audio.resumeAudio] The audio id '%d' in table '%s' is not exist!", audioId, cfgName))
    
    if (info.state ~= _M.State.paused) then return end
   
    if (info.behavior == _M.Behavior.music) then
        _engine:resumeMusic()
    else
        _engine:resumeEffect(info.playingId)
    end
    
    info.state = _M.State.playing
    
    -- Check stop using duration if not in loop mode
    if (not info.isLoop) then
        info:scheduleForStop(info.duration - info.playingParams.duration)
    end
end

--[[--
Stop an audio by specified audio id

@param  #number audioId         audio id
@param  #string cfgName         config name where the audio belongs. default "main"
--]]--
function _M.stopAudio(audioId, cfgName)
    cfgName = cfgName or "main"
    assert(_M._configs[cfgName], string.format("[lc.Audio.stopAudio] The info table '%s' is not exist!", cfgName))

    local info = _M._configs[cfgName][audioId]
    assert(info, string.format("[lc.Audio.stopAudio] The audio id '%d' in table '%s' is not exist!", audioId, cfgName))
    
    if (info.state == _M.State.idle or info.state == _M.State.unloaded) then return end
   
    if (info.behavior == _M.Behavior.music) then
        _engine:stopMusic(false)
    else
        _engine:stopEffect(info.playingParams.id)
    end
    
    handleAudioStop(info)
end

--[[--
Stop all audios for the specified behavior and cfgName

@param  #number behavior        audio behavior. default to all behaviors
@param  #string cfgName         name to identify the audios contained in this plist file. default to all configs
--]]--
function _M.stopAllAudio(behavior, cfgName)
    local audiosToBeStopped = {}
    for _, info in pairs(_playingAudioList) do
        if ((not behavior or info.behavior == behavior) and (not cfgName or info.cfgName == cfgName)) then
            table.insert(audiosToBeStopped, info)
        end
    end
    
    for _, info in ipairs(audiosToBeStopped) do
        _M.stopAudio(info.id, info.cfgName)
    end
end

--[[--
Stop all audios for the specified behavior and cfgName

@param  #number volume		    volume to be set (0-1.0)
@param  #number behavior        audio behavior. default to all behaviors
--]]--
function _M.setAudioVolume(volume, behavior)
    if (not behavior or behavior == _M.Behavior.effect) then
        _engine:setEffectsVolume(volume)
    end
    
    if (not behavior or behavior == _M.Behavior.music) then
        _engine:setMusicVolume(volume)
    end
end

--[[--
Set whether is mute for audio

@param  #boolean isMute         whether is mute for audio
@param  #number behavior		audio behavior. default to all behaviors
@param  #string cfgName         config name where the audio belongs. default to all configs
--]]--
function _M.setIsMute(isMute, behavior, cfgName)
    if behavior then
        _muteFlag = isMute and bit.bor(_muteFlag, bit.lshift(1, behavior)) or bit.band(_muteFlag, bit.bnot(bit.lshift(1, behavior)))
    else
        _muteFlag = isMute and 0x3 or 0x0
    end
    
    if (isMute) then
        local audiosToBeStopped = {}
        for _, info in pairs(_playingAudioList) do
            if ((not behavior or info.behavior == behavior) and (not cfgName or info.cfgName == cfgName)) then
                if (info.switch == _M.SwitchType.yes_once) then
                    table.insert(audiosToBeStopped, info)
                elseif (info.switch == _M.SwitchType.yes_replay) then
                    _M.pauseAudio(info.id, info.cfgName)
                end    
            end
        end
        
        for _, info in ipairs(audiosToBeStopped) do
            _M.stopAudio(info.id,info.cfgName)
        end
    else
        for _, info in pairs(_playingAudioList) do
            if ((not behavior or info.behavior == behavior) and (not cfgName or info.cfgName == cfgName)) then
                if (info.switch == _M.SwitchType.yes_replay) then
                    _M.resumeAudio(info.id, info.cfgName)
                end
            end
        end
    end
end

--[[--
Unload all audios for the specified behavior and cfgName

@param  #number behavior        audio behavior. default to all behaviors
@param  #string cfgName         name to identify the audios contained in this plist file. default to all configs
--]]--
function _M.unloadAllAudio(behavior, cfgName)
    if (not _M._configs) then return end
    
    for k, infoList in pairs(_M._configs) do
        if (not cfgName or k == cfgName) then
            for _, info in ipairs(infoList) do
                if (not behavior or info.behavior == behavior) then
                    unloadAudio(info.id, cfgName)
                end
            end
        end
    end
end

--[[--
Stop all playing audio, clear all audio info and release all memories
--]]--
function _M.clear()
    _M.unloadAllAudio()
    _M._configs = nil
    playingAudioList = nil
end

lc.Audio = _M
return _M