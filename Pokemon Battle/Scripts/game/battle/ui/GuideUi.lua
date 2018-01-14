local _M = class("GuideUi", lc.ExtendUIWidget)
GuideUi = _M

function _M.create(scene, callback)
    local ui = _M.new(lc.EXTEND_WIDGET)
    ui:init(scene, callback)
    return ui
end

function _M:init(scene, callback)
    self._callback = callback
    self:setContentSize(scene:getContentSize())
    self:setTouchEnabled(true)

    local bg = lc.createSprite('res/bat_scene/bat_scene_guide.jpg')
    lc.addChildToCenter(self, bg)

    local bones = DragonBones.create("hmssn")
    bones:setScale(1.3)
    bones:gotoAndPlay("effect")
    lc.addChildToPos(self, bones, cc.p(lc.w(self) / 2 - 150, 280))

    local labelBg = lc.createMaskLayer(160, lc.Color3B.black, cc.size(V.SCR_W, 110))
    labelBg:setTouchEnabled(false)
    self:addChild(labelBg)

    local title = V.createTTF('', V.FontSize.M2)
    title:setAnchorPoint(0, 0.5)
    lc.addChildToPos(labelBg, title, cc.p(20, 80))
    self._title = title

    local label = V.createTTF('', V.FontSize.M2)
    label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(labelBg, label, cc.p(20, 40))
    self._label = label

    self:updateText()

    self:addTouchEventListener(function(sender, type)
        if type == ccui.TouchEventType.ended then
            self:nextStep()
        end
    end)

    --[[
    performWithDelay(self, function()
        local continue = V.createTTF(Str(STR.CONTINUE), V.FontSize.M1)
        continue:runAction(lc.rep(lc.sequence(lc.fadeIn(0.5), 0.5, lc.fadeOut(0.5))))
        lc.addChildToPos(self, continue, cc.p(lc.w(self) / 2, 40))

        self:addTouchEventListener(function(sender, type)
            if type == ccui.TouchEventType.ended and not self._isCutting then
                lc.Audio.playAudio(AUDIO.E_GUIDE_CUT)
                bones:gotoAndPlay("effect2")

                self._isCutting = true

                performWithDelay(self, function()
                    callback()
                    self:removeFromParent()
                end, bones:getAnimationDuration("effect2"))
            end
        end)

    end, bones:getAnimationDuration("effect1"))
    ]]

    return true
end

function _M:onEnter()
    lc.Audio.playAudio(AUDIO.M_GUIDE)
end

function _M:nextStep()
    local guideInfo = Data._guideInfo[P._guideID]
    if guideInfo._saveStep ~= 0 then
        P._guideID = guideInfo._saveStep
        self._callback()
        self:removeFromParent()
    else
        P._guideID = P._guideID + 1
        self:updateText()
    end
end

function _M:updateText()
    local guideInfo = Data._guideInfo[P._guideID]
    self._title:setString('['..(guideInfo._param == 0 and Str(STR.PLAYER) or Str(STR.NPC_NAME))..']')
    self._label:setString(Str(guideInfo._nameSid))
end

return _M