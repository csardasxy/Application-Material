local _M = class("VideoScene", require("BaseScene"))

function _M.create()
    return lc.createScene(_M)
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    lc.UserDefault:setBoolForKey(ClientData.ConfigKey.video_played, true)
    self:playVideo()
end

function _M:onExit()
    _M.super.onExit(self)
end

function _M:onCleanup()
    _M.super.onCleanup(self)
end

function _M:init()
    if not _M.super.init(self) then return false end

    self._isGuideOnEnter = false

    --[[
    local label = V.createBMFont(V.BMFont.huali_26, Str(STR.DOUBLECLICK_SKIP_VIDEO))
    label:setColor(lc.Color3B.gray)
    lc.addChildToPos(self, label, cc.p(lc.cw(self), lc.h(self) - lc.ch(label) - 10), 1)
    label:runAction(lc.rep(lc.sequence(0.5, lc.hide(), 0.5, lc.show())))
    ]]

    return true
end

function _M:playVideo()
    if lc.PLATFORM == cc.PLATFORM_OS_ANDROID or lc.PLATFORM == cc.PLATFORM_OS_IPHONE or lc.PLATFORM == cc.PLATFORM_OS_IPAD then
        local videoPlayer = ccexp.VideoPlayer:create()
        videoPlayer:setPosition(cc.p(0,0))
        videoPlayer:setAnchorPoint(cc.p(0, 0))
        videoPlayer:setContentSize(V.SCR_SIZE)
        videoPlayer:setFullScreenEnabled(true)
        videoPlayer:setKeepAspectRatioEnabled(true)
        videoPlayer:addEventListener(function(sender, event) self:onVideoEvent(sender, event) end)
        self:addChild(videoPlayer)

        videoPlayer:setFileName(lc.File:fullPathForFilename("res/video.mp4"))
        videoPlayer:play()
    else
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(1),
            cc.CallFunc:create(function () self:switchScene() end)
        ))
    end
end

function _M:onVideoEvent(sender, event)
    if event == ccexp.VideoPlayerEvent.COMPLETED or event == ccexp.VideoPlayerEvent.STOPPED then
        self:switchScene()
    end
end

function _M:onIdle() 
    lc.Director:updateTouchTimestamp()
end

function _M:switchScene()
    V.popScene(false)
end

return _M