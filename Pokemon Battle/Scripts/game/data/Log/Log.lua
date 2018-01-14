local _M = class("Mail")

function _M:ctor(isAttack, pbLog)
    self._id = pbLog.id
    self._isAttack = isAttack
    self._type = pbLog.battle_type

    if pbLog then
        self._timestamp = pbLog.timestamp / 1000
        self._resultType = pbLog.result_type
        self._battleType = pbLog.battle_type
        self._isAvailable = pbLog.is_available
        self._replayId = pbLog.replay_id
        self._trophy = pbLog.trophy
        self._city = pbLog.city
        
        self._opponent = require("User").create(pbLog.opponent_info)
        self._player = require("User").create(pbLog.player_info)
    end
end

function _M:isLocal()
    return self._type == Battle_pb.PB_BATTLE_PLAYER
end

return _M
