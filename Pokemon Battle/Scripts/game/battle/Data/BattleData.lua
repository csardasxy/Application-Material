local _M = {}
BattleData = _M

_M.MAX_POWER_COUNT = 6
_M.MAX_BALL_COUNT = 6

_M.TAG_BATTLE_LIST_DIALOG = 1230

_M.Status = 
{
    default                     = 0,
    wait_opponent               = 1,
    battle_start                = 2,
    battle_end                  = 3,
    
    -- macro status
    round_begin                 = 11,
    deal                        = 12,
    use                         = 13,
    action                      = 14,
    round_end                   = 15,
    initial_deal                = 16,
    select_main                 = 17,
    
    before_account_status       = 21,
    after_account_status        = 22,
    before_account_reorder      = 23,
    after_account_reorder       = 24,
    before_account_pos_change   = 25,
    after_account_pos_change    = 26,
    before_account_halo         = 27,
    after_account_halo          = 28,
    before_account_spell        = 29,
    after_account_spell         = 30,
    before_account_event        = 33,
    after_account_event         = 34,
    before_account_finish       = 35,
    after_account_finish        = 36,
    before_account_trap         = 37,
    after_account_trap          = 38,
    
    -- micro status
    account_status              = 111,
    account_reorder             = 112,
    account_pos_change          = 113,
    account_halo                = 114,
    account_trap                = 115,
    
    spelling                    = 121,
    under_spell                 = 122,
    under_defend_spell          = 123,
    under_spell_damage          = 124,
    under_counter_spell         = 125,
    account_spell               = 126,
    after_spell                 = 127,
    end_spell                   = 128,
    
    account_event               = 151,
    
    account_finish              = 161,

    -- use card
    try_use_card                = 211,
    do_use_card                 = 212,
    wait_oppo_use_card          = 213,
    send_battle_end             = 214,
    
    wait_observe_use_card       = 216,
   
    use_card                    = 221,
    
    -- score
    update_score_damage         = 231,
    update_score_destroy_card   = 232,

    -- fortress skill
    change_fortress_skill       = 241,

    -- pvp timing
    pvp_timing_begin            = 251,
}

_M.CardStatus = 
{
    leave                   = 1,
    pile 			        = 2,
    hand			        = 3,
    board		            = 4,
    grave                   = 5,
    cover                   = 9,
    show                    = 10,
    fortress                = 11,
}

_M.CardStatusVal = 
{
    e2x_fast                = 1,
    e2x_fast_def            = 2,

    b2b_oppo_once           = 11,
    b2b_oppo_forever        = 12,
    b2b_oppo_rob_horse      = 13,
    
    b2h_oppo                = 21,
    b2p_oppo                = 22,
    b2h_oppo_once           = 23,
    
    e2h_copy_oppo_hand      = 31,
    e2h_copy_oppo_board     = 32,
    e2h_self_new            = 33,

    h2b_normal              = 41,
    
    h2g_magic               = 51,
    h2g_trap                = 52,
    h2g_drop                = 53,

    h2l_temp                = 61,

    p2h_show                = 71,
    p2h_oppo                = 72,

    b2g_sacrifice           = 82,

    p2b_def                 = 91,

    r2b_compose             = 101,

    g2b_4111                = 111,
    g2b_5096                = 112,
    g2b_decompose           = 113,
    
    e2b_3136                = 122,
    e2b_5039                = 123,

    g2p_fast                = 131,

    p2g_fast                = 141,

    g2h_oppo                = 151,

    f2f_fortress_damaged    = 161,
    f2f_halo                = 162,

    b2l_evolve              = 171,
}

_M.PositiveType = 
{
    craze               = 1,

    powerMark           = 2,
    waterMark           = 6, 
    actionCraze         = 7,
    magicMark           = 8,
    roundMark           = 9,
    
    haloSkillBegin      = 10,
    invisible           = 10,
    irony               = 11,
    extraSkill          = 12,
    accurateArrow       = 13,
    magnetic            = 14,
    guard               = 15,
    mask                = 16,
    spellMaster         = 17,
    spellMaster2        = 18,
    spellMasterWu       = 19,
    changeRandom        = 20,
    poisonMaster        = 21,
    ignoreNegative      = 22,
    disableDyingSkill   = 23,
    lockAtk             = 24,
    ignoreOppoMonsterSkillDamageHalo    = 25,
    ignoreOppoMonsterSkillHalo          = 26,
    r4                  = 27,
    r5                  = 28,

    ---- must successive begin ----
    shieldHaloBegin     = 29,
    shieldHaloMonster   = 30,
    shieldHaloMagic     = 31,
    shieldHaloTrap      = 32,
    shieldHaloHp        = 33,
    shieldHaloEnd       = 33,

    haloSkillEnd        = 33,

    shieldBegin         = 34,
    shieldMonster       = 35,
    shieldMagic         = 36,
    shieldTrap          = 37,
    shieldHp            = 38,
    shieldEnd           = 38,

    shieldExBegin       = 39,
    shieldExMonster     = 40,
    shieldExMagic       = 41,
    shieldExTrap        = 42,
    shieldExHp          = 43,
    shieldExEnd         = 43,
    ---- must successive end ----

    pumpkinMark         = 45,
    dinosaurMark        = 46,

    count               = 46,
}

_M.NegativeType =
{
    -- common
    sleep               = 1,
    poison              = 2,
    burn                = 3,
    numb                = 4,
    chaos               = 5,
    
    -- damage
    damage              = 6,

    -- other non halo
    sleepOneRound       = 7,
    r1                  = 8,
    powerLock           = 9,

    count               = 9,

    -- not use now
    atkFrozen           = 10,
    boardLock           = 11,
    haloSkillBegin      = 12,
    haloSkillEnd        = 12,
}

_M.SkillProvider = 
{
    extra               = 1,
    given               = 2,
}

_M.CardPosChange = 
{
    random                  = 1,
    swap                    = 2,
    loop                    = 3,
    shiftleft               = 4,
    shiftright              = 5,
}

_M.UseCardType = 
{
    none                = 0,
    
    round               = 1,
    retreat             = 2,

    init_b1             = 11,
    init_bx             = 12,

    h2b                 = 21,
    swap                = 22,
    drop                = 23,

    spell               = 31,
}

_M.CardId = 
{
    attacker_base       = 1000,
    defender_base       = 2000,
}

_M.PlayerType = 
{
    player              = 1,
    opponent            = 2,
    observe             = 3,

    ai                  = 11,
    
    replay              = 21,
}

_M.MaxRound = 
{
    [1]         = 30,        -- level < 30
    [2]         = 30,       -- 30 <= level < 45
    [3]         = 30,       -- level >= 45
    
    [4]         = 30,       -- default
}

_M.NEGATIVE_COMMON = {_M.NegativeType.sleep, _M.NegativeType.poison, _M.NegativeType.burn, _M.NegativeType.numb, _M.NegativeType.chaos}
_M.NEGATIVE_CLEAR_WHEN_ROUND_END = {_M.NegativeType.sleepOneRound}
_M.NEGATIVE_CLEAR_WHEN_ROUND_BEGIN = {}
_M.POSITIVE_CLEAR_WHEN_ROUND_END = {}
_M.POSITIVE_CLEAR_WHEN_ROUND_BEGIN = {}

