local _M = class("Message")

local MarqueeManager = require("MarqueeManager")

function _M:ctor(pbMsg, pbMsgType)
    self._timestamp = pbMsg.timestamp / 1000

    local getField = function(name)
        if pbMsg:HasField(name) then
            return pbMsg[name]
        end
    end

    if pbMsgType == SglMsgType_pb.PB_TYPE_CHAT then
        self._user = require("User").create(pbMsg.user_info)
        if self._user then
            self._type = Data.MsgType.world
        else
            self._type = Data.MsgType.bulletin
        end

        self._content = pbMsg.content

    elseif pbMsgType == SglMsgType_pb.PB_TYPE_UNION_MESSAGE then
        self._user = require("User").create(pbMsg.user1)
        self._type = Data.MsgType.union

        if pbMsg:HasField("user2") then
            self._target = require("User").create(pbMsg.user2)
        end

        local action, param1, param2 = pbMsg.type, getField("param1"), getField("param2")
        if action == Union_pb.PB_UNION_JOIN then
            if self._target then
                self._content = string.format(Str(STR.BE_INVITED_TO).."%s", self._target._name, Str(STR.UNION_JOIN_NEWS))
            else 
                self._content = Str(STR.UNION_JOIN_NEWS)
            end
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_CREATE then
            self._content = string.format("%s|%s|", Str(STR.CREATE_UNION), self._user._unionName)
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_KICKOUT then
            self._content = string.format(Str(STR.UNION_KICKOUT_NEWS), self._target._name)
            self._clr = V.COLOR_TEXT_RED_DARK

        elseif action == Union_pb.PB_UNION_LEAVE then
            self._content = Str(STR.UNION_LEAVE_NEWS)
            self._clr = V.COLOR_TEXT_RED_DARK

        elseif action == Union_pb.PB_UNION_TO_CO_LEADER or action == Union_pb.PB_UNION_TO_MEMBER then
            self._content = string.format(Str(STR.UNION_CHANGE_JOB_NEWS), self._target._name, Str(STR.ROOKIE + self._target._unionJob - 1))
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == action == Union_pb.PB_UNION_TO_LEADER then
            self._content = Str(STR.UNION_TO_LEADER)
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_RESIGN then
            self._content = string.format(Str(STR.UNION_GIVE_LEADER_TO), self._target._name)
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_UPGRADE then
            self._content = string.format(Str(STR.UNION_UPGRADE_NEWS), param1)
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_DONATE then
            local res = pbMsg.resource[1]
--            if res.info_id == Data.ResType.union_gold then
--                self._content = string.format(Str(STR.NEWS_MEMBER_CONTRIBUTE), res.num, Str(STR.UNION_GOLD))
--            else
--                self._content = string.format(Str(STR.NEWS_MEMBER_CONTRIBUTE), res.num, Str(STR.UNION_WOOD))
--            end
            self._content = string.format(Str(STR.NEWS_MEMBER_CONTRIBUTE), res.num, Str(STR.SID_RES_NAME_13))
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_TECH_UPGRADE then
            local union = P._playerUnion:getMyUnion()
            if union then
                self._content = string.format(Str(STR.UNION_UPGRADE_TECH_NEWS), Str(union._techs[param2]._info._nameSid), param1)
                self._clr = V.COLOR_TEXT_ORANGE
            else
                self._content = ""
            end

        elseif action == Union_pb.PB_UNION_RESCUE then
            --self._content = string.format(Str(STR.NEWS_MEMBER_RESCUE), self._target._name, Str(Data._cityInfo[param1]._nameSid))            
            --self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_IMPEACH then
            self._content = Str(STR.UNION_IMPEACH_NEWS)
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_UNIMPEACH then
            self._content = Str(STR.UNION_UNIMPEACH_NEWS)
            self._clr = V.COLOR_TEXT_ORANGE

        elseif action == Union_pb.PB_UNION_IMPEACHED then
            self._content = Str(STR.UNION_IMPEACHED_NEWS)
            self._clr = V.COLOR_TEXT_RED_DARK

        else
            self._content = getField("message")
            if self._content == nil then
                self._content = ""
            end
        end

    elseif pbMsgType == SglMsgType_pb.PB_TYPE_NEWS then
        self._user = require("User").create(pbMsg.user1)
        self._type = Data.MsgType.bulletin

        if pbMsg:HasField("user2") then
            self._target = require("User").create(pbMsg.user2)
        end

        self._items = {}
        for _, res in ipairs(pbMsg.resource) do
            table.insert(self._items, {_infoId = res.info_id, _num = res.num, _isFragment = res.is_fragment, _level = res.level})
        end
        local item = self._items[1]

        local getItemTypeName = function(item)
            local info, type = Data.getInfo(item._infoId)
            if info ~= nil then
                return Str(info._nameSid), ClientData.getStrByCardType(type)
            else
                return '', ClientData.getStrByCardType(type)
            end
        end

        local what, param = pbMsg.what, getField("param")
        if what == News_pb.PB_NEWS_PURCHASE then
            self._content = string.format(Str(STR.NEWS_VIP), self._user._vip)

        elseif what == News_pb.PB_NEWS_LOTTERY then
            self._needMarquee = true

            local info = Data.getRecruiteInfo(param)
            local lotteryStr = Str(info._nameSid)
            local rpStr = Str(STR.RP_GOOD)
            local times = param % 100
            self._content = string.format(Str(STR.NEWS_LOTTERY), lotteryStr, times, getItemTypeName(item), #self._items > 1 and Str(STR.SO_ON) or "")

            if rpStr then
                self._content = rpStr..self._content
            end

        elseif what == News_pb.PB_NEWS_TRANSFORM then
            self._content = string.format(Str(STR.NEWS_REBIRTH), getItemTypeName(item))

        elseif what == News_pb.PB_NEWS_EXPEDITION then
            local name, typeStr = getItemTypeName(item)
            self._content = string.format(Str(STR.NEWS_EXPEDITION), typeStr, name)
            self._needMarquee = true

        elseif what == News_pb.PB_NEWS_RECRUIT then
            self._content = string.format(Str(STR.NEWS_RECRUIT), getItemTypeName(item))
            self._needMarquee = true

        elseif what == News_pb.PB_NEWS_VISIT then
            self._content = string.format(Str(STR.NEWS_VISIT), getItemTypeName(item))

        elseif what == News_pb.PB_NEWS_UNION_CREATE then
            self._content = string.format(Str(STR.NEWS_UNION_CREATE), pbMsg.union1.name)
            self._needMarquee = true

        elseif what == News_pb.PB_NEWS_UNION_UPGRADE then
            local union = pbMsg.union1
            self._content = string.format(Str(STR.NEWS_UNION_UPGRADE), union.name, union.level)

        elseif what == News_pb.PB_NEWS_OPEN_CHEST then
            self._content = string.format(Str(STR.NEWS_OPEN_CHEST), ClientData.getNameByInfoId(param), getItemTypeName(item), #self._items > 1 and Str(STR.SO_ON) or "")
            self._needMarquee = true

        elseif what == News_pb.PB_NEWS_ATTACK_WIN then
            --self._content = string.format(Str(STR.NEWS_COPY_PVP_ATTACK_WIN), self._target._name, Str(Data._cityInfo[param]._nameSid))
            --self:pushToMarquee(string.format("#|%s|#%s", self._user._name, self._content), true)

        elseif what == News_pb.PB_NEWS_DEFEND_WIN then
            self._content = string.format(Str(STR.NEWS_COPY_PVP_DEFEND_WIN), self._user._name)
            self:pushToMarquee(string.format("#|%s|#%s", self._target._name, self._content), true)

        elseif what == News_pb.PB_NEWS_BUY then
            local location
            if param == SglMsgType_pb.PB_TYPE_SHOP_BUY then
                location = Str(STR.RANDOM_MARKET)

            elseif param == SglMsgType_pb.PB_TYPE_SHOP_BUY_PVP then
                location = Str(STR.FLAG_MARKET)

            elseif param == SglMsgType_pb.PB_TYPE_UNION_BUY then
                location = Str(STR.UNION_MARKET)

            end

            self._content = string.format(Str(STR.NEWS_BUY), location, ClientData.getNameByInfoId(self._items[1]._infoId))
            self:pushToMarquee(string.format("#|%s|#%s", self._user._name, self._content))

        elseif what == News_pb.PB_NEWS_RANK then
            self._content = string.format(Str(STR.NEWS_RANK_CHANGE), param)
            self:pushToMarquee(string.format("#|%s|#%s", self._user._name, self._content), true)

        elseif what == News_pb.PB_NEWS_RANK_LADDER then
            self._content = string.format(Str(STR.NEWS_RANK_LADDER_CHANGE), param)
            self:pushToMarquee(string.format("#|%s|#%s", self._user._name, self._content), true)

        else
            self._content = ""
        end

    elseif pbMsgType == SglMsgType_pb.PB_TYPE_BATTLE_SHARE then
        self._log = require("Log").new(pbMsg.is_attack, pbMsg.log)

        if pbMsg:HasField("user_info") then
            if self._log._isAttack then
                self._user = self._log._player
                self._opponent = self._log._opponent
                self._resultType = self._log._resultType
            else
                self._user = self._log._opponent
                self._opponent = self._log._player
                self._resultType = -self._log._resultType
            end
            
            self._content = pbMsg.text
            if self._content == "" or self._content == Str(STR.SHARE_BATTLE_MSG) then
                self._content = string.format("|%s|"..Str(STR.SHARE_BATTLE_MSG), pbMsg.user_info.name)
            else
                self._content = string.format(Str(STR.SHARE_BATTLE_BY_USER), pbMsg.user_info.name)..self._content
            end
        else
            self._user = self._log._player
            self._opponent = self._log._opponent
            self._resultType = self._log._resultType

            self._content = Str(STR.SHARE_BATTLE_BY_SYS)
        end

        local fmt, logTypeName = string.format("|\\255.255.255\\%s|", Str(STR.BRACKETS_S)).."%s"
        if self._log._type == Battle_pb.PB_BATTLE_PLAYER then
            logTypeName = Str(STR.FIND_TROPHY_TITLE)
        elseif self._log._type == Battle_pb.PB_BATTLE_WORLD_LADDER then
            logTypeName = Str(STR.FIND_CLASH_TITLE)
        elseif self._log._type == Battle_pb.PB_BATTLE_WORLD_LADDER_EX then
            logTypeName = Str(STR.FIND_ARENA_TITLE)
        end
        self._content = string.format(fmt, logTypeName, self._content)

        self._type = Data.MsgType.battle
        self._round = pbMsg.round

        self._watchIds = {}
        if pbMsg.watched then
            for _, id in ipairs(pbMsg.watched) do
                self._watchIds[id] = true
            end
            self._watchIdsCount = #pbMsg.watched
        end

        self._likeIds = {}
        for _, id in ipairs(pbMsg.thumbs_up) do
            self._likeIds[id] = true
        end
        self._likeIdsCount = #pbMsg.thumbs_up

    elseif pbMsgType == SglMsgType_pb.PB_TYPE_FRIEND_BATTLE_START then
        self._user = require("User").create(pbMsg.user_info)
        self._type = Data.MsgType.battle
        self._battleId = pbMsg.id
        self._content = Str(STR.FRIEND_BATTLE_UNDER)

    elseif pbMsgType == SglMsgType_pb.PB_TYPE_FRIEND_BATTLE then
        self._type = Data.MsgType.union
        self._content = Str(STR.FRIEND_BATTLE_INVITE)
        self._clr = V.COLOR_TEXT_ORANGE

        self._battleId = pbMsg.battle_id
        self._unionId = pbMsg.union_id
        self._user = require("User").create(pbMsg.user1)
        if pbMsg:HasField("user2") then
            self._opponent = require("User").create(pbMsg.user2)
        end
        self._isValid = pbMsg.is_valid
        if pbMsg:HasField("result") then
            self._resultType = pbMsg.result.result_type
            self._replayId = pbMsg.result.replay_id
        end
        
    end
end

function _M:pushToMarquee(msg, hiddenInChat)
    if math.floor(self._timestamp) > math.ceil(P._loginTime) then
        MarqueeManager.push(msg)
    end

    self._hiddenInChat = hiddenInChat
end

return _M
