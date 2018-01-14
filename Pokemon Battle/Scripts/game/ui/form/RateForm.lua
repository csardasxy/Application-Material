local _M = class("RateForm", BaseForm)
local InputForm = require("InputForm")

local FORM_SIZE = cc.size(600, 410)

function _M.create(callback)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(callback)
    return panel    
end

function _M:init(callback)
    _M.super.init(self, FORM_SIZE, Str(STR.RATE), bor(BaseForm.FLAG.BASE_TITLE_BG, BaseForm.FLAG.PAPER_BG))
    
    local form = self._form

    local tip = V.createBoldRichText(Str(STR.RATE_TIP), V.RICHTEXT_PARAM_DARK_S1)
    lc.addChildToPos(form, tip, cc.p(lc.w(form) / 2, lc.bottom(self._titleFrame) - 20 - lc.h(tip) / 2))

    local btnRate = V.createScale9ShaderButton("img_btn_2", function()
        self:hide()
        lc.App:openUrl(lc.App:getAppRateUrl())
    
        ClientData.sendUserEvent({type = "rate", action = "goto"})
        
    end, V.CRECT_BUTTON, 200)
    btnRate:addLabel(Str(STR.RATE_GO))
    lc.addChildToPos(form, btnRate, cc.p(lc.left(tip) + lc.w(btnRate) / 2 + 20, lc.bottom(tip) - 30 - lc.h(btnRate) / 2))

    local btnAdvice = V.createScale9ShaderButton("img_btn_1", function()
        self:hide()
        InputForm.create(InputForm.Type.FEEDBACK):show()

        ClientData.sendUserEvent({type = "rate", action = "feedback"})

    end, V.CRECT_BUTTON, 200)
    btnAdvice:addLabel(Str(STR.RATE_ADVICE))
    lc.addChildToPos(form, btnAdvice, cc.p(lc.x(btnRate), lc.bottom(btnRate) - 10 - lc.h(btnAdvice) / 2))

    local btnRefuse = V.createScale9ShaderButton("img_btn_1", function()
        self:hide()
        ClientData.sendUserEvent({type = "rate", action = "refuse"})

    end, V.CRECT_BUTTON, 200)
    btnRefuse:addLabel(Str(STR.RATE_REFUSE))
    lc.addChildToPos(form, btnRefuse, cc.p(lc.x(btnRate), lc.bottom(btnAdvice) - 10 - lc.h(btnRefuse) / 2))

    local npc = lc.createSprite("card_thu_0")
    lc.addChildToPos(form, npc, cc.p(lc.w(form) - lc.w(npc) / 2 - 40, lc.h(npc) / 2 + 32))

    -- Do not close the form, remove old listeners and add a empty listener
    self:addTouchEventListener(function() end)
    self._btnBack:setVisible(false)
end

return _M