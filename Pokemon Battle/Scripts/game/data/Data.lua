local _M = {}

_M.INFO_ID_GROUP_SIZE                       = 1000
_M.INFO_ID_GROUP_SIZE_LARGE                 = 10000
_M.INFO_ID_FRAGMENT_SIZE_LARGE              = 100000

_M.CARD_MAX_LEVEL                           = 5
_M.CARD_COUNT_OF_INITIAL_DEAL               = 5
_M.CARD_COUNT_OF_ROUND_DEAL                 = 1
_M.MAX_CARD_COUNT_ON_BOARD                  = 6
_M.MAX_CARD_COUNT_ON_COVER                  = 5
_M.MAX_CARD_COUNT_IN_HAND                   = 16
_M.MAX_CARD_COUNT_IN_HAND_AFTER_DROP        = 10

_M.ATTACKING_SKILL_ID                       = 1000
_M.POWER_CAN_USE_COUNT                      = 1
_M.POWER_DEAL_COUNT                         = 1

_M.MAX_TROOP_CARD_COUNT                     = 40
_M.MIN_TROOP_CARD_COUNT                     = 30
_M.MIN_TROOP_CARD_COUNT_2                   = 40
_M.MIN_RARE_TROOP_CARD_COUNT                = 1
_M.MAX_RARE_TROOP_CARD_COUNT                = 15
_M.MAX_UNION_TROOP_CARD_COUNT               = 60

_M.DAY_SECONDS                              = 24 * 3600
_M.SERVER_TIME_ZONE                         = 8 * 3600

_M.UNION_SHOP_PACKAGE_ID                    = 1

_M.GROUP_NUM                                = 2

_M.DJLX_REGION_ID_BASE                      = 161

_M.RANK_TROPHY_VISIBLE_LEVEL                = 30

_M.CardType =
{
    res                                     = 0,
    monster                                 = 1,
    monster_ex                              = 2,
    magic                                   = 3,
    trap                                    = 4,
    rare                                    = 99,

    monster_skin                            = 5,
    rare_skin                               = 6,
    
    props                                   = 7,

    nature                                  = 11,
    category                                = 12,
    keyword                                 = 13,

    fragment                                = 14,

    fortress                                = -1,
    boss                                    = -2,

    other                                   = 60
}

_M.BaseCardTypes =
{
    _M.CardType.monster,
    _M.CardType.magic,
    _M.CardType.trap,
}

_M.CardQuality = 
{
    C                                       = 1,
    U                                       = 2,
    R                                       = 3,
    RR                                      = 4,
    SR                                      = 5,
    HR                                      = 6,
    UR                                      = 7,
}

_M.CardNature = 
{
    grass                                   = 1,
    fire                                    = 2,
    water                                   = 3,
    thunder                                 = 4,
    psycho                                  = 5,            
    might                                   = 6, 
    dark                                    = 7, 
    steel                                   = 8, 
    god                                     = 9, 
    dragon                                  = 10, 
    common                                  = 11, 

    count                                   = 11
}

_M.CardCategory = 
{
    magician                                = 1,
    dragon                                  = 2,
    machinery                               = 3,
    devil                                   = 4,
    beast                                   = 5,
    warrior                                 = 6,
    rock                                    = 7,
    water                                   = 8,
    sea_dragon                              = 9,
    worm                                    = 10,
    beast_warrior                           = 11,
    dinosaur                                = 12,
    bird_beast                              = 13,
    angle                                   = 14,
    insect                                  = 15,
    fish                                    = 16,
    undead                                  = 17,
    plant                                   = 18,
    fire                                    = 19,
    imagery_god                             = 20,
    thund                                   = 21,
}

_M.CardKeyword = 
{
    hmfs                                    = 1,
    qybl                                    = 2,
    em                                      = 3,
    cszs                                    = 4,
    lzq                                     = 5,
    ymx                                     = 6,
    ys                                      = 7,
    zhy                                     = 8,

}

_M.CardOption = 
{
    hide_atk                                = 1,
    hide_def                                = 2,
    is_token                                = 4,
}

_M.ActType =
{
    forum                                   = 1,
    level                                   = 2,
    weekend                                 = 3,
    login                                   = 4,
    chapter                                 = 5,
    charge                                  = 6,
    score                                   = 7,
    market                                  = 8,
    consume                                 = 9,
    rank                                    = 10,
    festival                                = 11,
    tavern                                  = 12,
    region_time                             = 13,
    split                                   = 14,
    gift                                    = 15
}

_M.SkillType = 
{
    all                                     = 0,
    
    monster_attack                          = 1,
    monster_body                            = 2,
    monster_strength                        = 3,
    mosnter_ability                         = 4,

    magic_item                              = 5,
    magic_equip                             = 6,
    magic_special                           = 7,

    trapHalo                                = 8,
    
    fortress                                = 9,

    shield                                  = 11,
    shieldEx                                = 12,
}

_M.SkillMode = 
{
    once                                    = 0,
    halo                                    = 1,
    using                                   = 2,    
    bcs2gl                                  = 3,  
    bcs2_                                   = 4,
    choice                                  = 6,
    sacrifice                               = 7,
    cost                                    = 8,
    g2b                                     = 9,

    spelling                                = 21,
    under_spell                             = 22,
    under_defend_spell                      = 23,
    under_spell_damage                      = 24,
    under_counter_spell                     = 25,
    after_spell                             = 26,
    under_ruse_casted                       = 27,
    under_ruse_using_casted                 = 28,
    
    initiative                              = 31,
    
    round_begin                             = 41,
    round_end                               = 42,
    oppo_round_begin                        = 43,
    oppo_round_end                          = 44,

    h2g_by_self                             = 51,  
    h2g_by_oppo                             = 52,
    p2g_by_self                             = 53,  
    p2g_by_oppo                             = 54,

    magic                                   = 61,
    trap                                    = 71,

    use_disable                             = 81,
    use_normal_disable                      = 82,
    use_special_disable                     = 83,
    use_special_disable_except              = 84,
    use_specific_by_condition               = 85,
    use_specific_by_another_card            = 86,

    in_grave                                = 91,

    fortress_damaged                        = 101,
    oppo_fortress_damaged                   = 102,

    magic_casted                            = 111,
    oppo_magic_casted                       = 112,
    trap_casted                             = 113,
    oppo_trap_casted                        = 114,

    card_destroyed_from_bcs                 = 121,
    oppo_card_destroyed_from_bcs            = 122,
    card_destroyed_from_hand                = 123,
    oppo_card_destroyed_from_hand           = 124,
    card_destroyed_from_pile                = 125,
    oppo_card_destroyed_from_pile           = 126,
}

_M.SkillTargetType = 
{
    none                                    = 0,
    
    self_board_card                         = 1,
    oppo_board_card                         = 2,
    board_card                              = 3,
}

_M.MagicTrapType = 
{
    item                                    = 11,
    equip                                   = 12,
    special                                 = 13,
    power                                   = 14,
}

_M.ResType = 
{
    unknown                                 = 0,
    gold                                    = 1,
    grain                                   = 2,
    ingot                                   = 3,
    exp                                     = 4,
    ladder_trophy                           = 5,
    clash_trophy                            = 6,
    character_exp                           = 7,
    achieve_point                           = 8,
    union_gold                              = 11,
    union_wood                              = 12,
    union_act                               = 13,
    union_personal_power                    = 14,
    union_battle_trophy             = 15,
    dark_trophy                        = 16,
    ghost                                   = 20,
    blood_jade                              = 21,
}

_M.MapType =
{
    plain                                   = 0,
    river                                   = 1,
    mountain                                = 2
}

_M.CityType = 
{
    big                                     = 1,
    middle                                  = 2,
    small                                   = 3,
}

_M.WorldDisplay =
{
    normal                                  = 1,
    middle                                  = 2,
    hard                                    = 3,
    map                                     = 4
}

_M.FixityId = 
{
    residence                               = 1002,
    farmland                                = 1003,
    barrack                                 = 1004,
    factory                                 = 1005,
    manage_troop                            = 1006,
    tavern                                  = 1007,
    market                                  = 1008,
    blacksmith                              = 1009,
    stable                                  = 1010,
    library                                 = 1011,
    union                                   = 1012,
    casino                                  = 1013,
    traincamp                               = 1014,
    guard                                   = 1015,
    depot                                   = 1016,
    duel                                    = 1017,
    skin_shop                               = 1018,

    activity                                = 2000,
    xmas                                    = 2001,
}

_M.PropsType = 
{
    box                                     = 1,
    consumable                              = 2,
    token                                   = 3,
    
    artifact                                = 6,
}

_M.PropsId = 
{
    orange_hero_f_box                       = 7001,
    purple_hero_f_box                       = 7003,
    obelisk_badge                           = 7006,
    recruit_token                           = 7010,
    evolute_material                        = 7011,
    refresh_token                           = 7012,
    orange_horse_f_box                      = 7013,
    purple_horse_f_box                      = 7014,
    dust_monster                            = 7015,
    dust_magic                              = 7016,
    dust_trap                               = 7017,
    dust_rare                               = 7018,
    flag                                    = 7019,
    stone_rare                              = 7020,
    stone_legend                            = 7021,
    flower_rare                             = 7022,
    flower_legend                           = 7023,
    yubi                                    = 7024,
    polish                                  = 7025,
    weapon_box_rare                         = 7026,
    armor_box_rare                          = 7027,
    weapon_box_legend                       = 7028,
    armor_box_legend                        = 7029,
    sweep_card                              = 7030,
    horse_shoes                             = 7031,
    horse_armor                             = 7032,

    union_create                        = 7038,

    moon_cake                               = 7053,
    star_badge                              = 7054,
    hero_box_wei                            = 7055,
    hero_box_shu                            = 7056,
    hero_box_wu                             = 7057,
    hero_box_qun                            = 7058,
    equip_box_legend                        = 7059,
    ghost_box                               = 7060,

    pumpkin_pie                             = 7093,
    pumpkin_box                             = 7094,
    toffees                                 = 7095,

    iron_book                               = 7096,
    officer_seal                            = 7097,
    vip_card                                = 7098,

    miracle_indicator                       = 7101,
    millennium_block                        = 7102,
    dimension_bottle                        = 7103,
    lottery_token                           = 7104,
    rare_package_ticket                     = 7105,
    ladder_ticket                           = 7106,
    legend_chest                            = 7107,
    magic_dust                              = 7108,
    skin_crystal                            = 7109,
    rare_coin                               = 7110,
    character_package_ticket                = 7111,
    rare_silver_coin                        = 7112,
    times_package_ticket                = 7113,
    void_diamond                        = 7114,
    common_fragment                 = 7115,
    exp_bottle_s                            = 7116,
    exp_bottle                              = 7117,

    union_fund                              = 7130,
    dragon_flag                             = 7131,

    monster_stone_n			                = 7201,
    monster_stone_r                         = 7202,
    monster_stone_sr	                    = 7203,
    monster_stone_ur	                    = 7204,
    
    magic_stone_n		                    = 7211,
    magic_stone_r                           = 7212,
    magic_stone_sr                          = 7213,
    magic_stone_ur                          = 7214,
    
    trap_stone_n                            = 7221,
    trap_stone_r                            = 7222,
    trap_stone_sr                           = 7223,
    trap_stone_ur                           = 7224,
    
    rare_stone_n                            = 7231,
    rare_stone_r                            = 7232,
    rare_stone_sr                           = 7233,
    rare_stone_ur                           = 7234,
    
    special                                 = 7500,
    avatar_frame                            = 7500,
    avatar_frame_national_day               = 7501,
    avatar_frame_level_rank                 = 7502,
    avatar_frame_level_rank1                = 7503,
    avatar_frame_level_rank2                = 7504,
    avatar_frame_level_rank3                = 7505,
    avatar_frame_xmas                       = 7506,
    avatar_frame_xmas_1                     = 7507,
    avatar_frame_xmas_2                     = 7508,
    avatar_frame_clash_1                    = 7509,
    avatar_frame_clash_2                    = 7510,
    avatar_frame_clash_3                    = 7511,
    avatar_frame_clash_4                    = 7512,

    card_back                               = 7600,
    card_back_moon_day                      = 7601,
    card_back_xmas                          = 7602,

    clash_chest                             = 7800,
    clash_chest_end                         = 7856,

    ladder_chest                            = 7900,
    ladder_chest_end                        = 7914,
}

_M.BonusType = 
{
    lord                                    = 1,
    character                               = 2,
    equip                                   = 3,
    horse                                   = 4,
    book                                    = 5,
    daily_task                              = 6,
    week_checkin                            = 7,
    online                                  = 8,
    login                                   = 9,
    month_checkin                           = 10,
    vip_daily                               = 11,
    grain                                   = 12,
    month_card                              = 13,
    guide                                   = 14,
    level                                   = 15,
    union                                   = 16,
    novice                                  = 17,
    pass_chapter                            = 18,
    clash_target                            = 19,
    activity                                = 20,
    fund_level                              = 21,
    fund_all                                = 22,
    invite                                  = 23,
    facebook                                = 24,
    return_to_game                          = 30,
    clash                                     =31,--巅峰对决
--    clash                                     =
    clash_conti                          =32,--巅峰对决连胜
    clash_legacy                        =33,--巅峰对决法老的遗产
    clash_local                       =34,--巅峰对决本服冠军
    clash_zone                          =35,--巅峰对决跨服冠军
    arena_once                          =36,
    arena_all                               =37,
    arena_12                            = 38,
    gold_gain                                    =41,--巅峰对决获得的金币
    card_sr                                 =42,
    card_ur                                 =43,
    login_day                           =44,
    any_level                           = 45,
    gold_cost                               =51,
    gem_cost                            =52,
    card_package                        =53,--抽%d包卡牌
    bottle                                  =54,--异次元漂流瓶
    teach                                   = 60,
    daily_active                            = 61,
    fund_task                               = 70,--最多攒五个的每日任务

    send                                    = 75,
}

_M.CheckinType = 
{
    month_checkin                           = 1,
    week_checkin                            = 2,
    vip                                     = 3,
    month_card                              = 4,
    novice                                  = 5,
    online                                  =6,
    number                                  = 6,
}



_M.DailyTaskType = 
{
    upgrade_hero                            = 1,
    lottery_hero                            = 2,
    collect_in_residence                    = 3,
    collect_in_farmland                     = 4,
    player_battle_win                       = 5,
    upgrade_equip                           = 6,
    challenge_elite                         = 7,
    city_battle_win                         = 8,
    collect_fragment                        = 9,
    rob_horse                               = 10,
    upgrade_horse                           = 11,
    
    expedition                              = 14,
    copy_boss                               = 16,
    open_box                                = 17,
    challenge_uboss                         = 18
}

_M.ActivityTaskType =
{
    pvp                                     = 101,
    exchange_minor                          = 103,
    exchange_daily                          = 104,
    exchange_once                           = 105
}

_M.MainTaskType = 
{
    chapter                                 = 0,
    level                                   = 1,
    card                                    = 2
}

_M.PurchaseType = 
{
    product_1                               = 1,
    product_2                               = 2,
    product_3                               = 3,
    product_4                               = 4,
    product_5                               = 5,
    product_6                               = 6,
    product_7                               = 7,
    product_8                               = 8,

    month_card_1                            = 101, 
    month_card_2                            = 102, 
    fund                                    = 103,
    daily_1                                 = 104,
    daily_2                                 = 105,

    package_1                               = 201,
    package_2                               = 202,
    package_3                               = 203,
    package_4                               = 204,
    package_5                               = 205,
    package_6                               = 206,

    limit_1                                 = 301,
    limit_2                                 = 302,
    limit_3                                 = 303,
    limit_4                                 = 304,
    limit_5                                 = 305,

    return_to_game                          = 401,
    ad_recharge                             = 402,
    ad_package                              = 403,

    checkin                                 = 501,
    fund_task                               = 502,
}

_M.DropType = 
{
    challenge                               = 1001,
    copy                                    = 1002,
}

_M.CopyType =
{
    pvp                                     = 0,

    group_elite                             = 1,
    group_boss                              = 2,
    group_commander                         = 3,
    group_expedition                        = 4,

    group_count                             = 4,

    elite                                   = 11,
    boss                                    = 21,
    commander                               = 31,
    expedition                              = 41,
    expeidtion_ex                           = 51,
}

_M.BossType = 
{
    toad                                    = 1,
}

_M.HelpType = 
{
    herocenter                              = 1,
    barrack                                 = 2,
    blacksmith                              = 3,
    stable                                  = 4,
    market                                  = 5,
    tavern                                  = 6,
    heromansion                             = 7,
    
    seek                                    = 9,
    elite                                   = 10,
    rob_horse                               = 11,
    expedition                              = 12,
    library                                 = 13,
    race                                    = 14,
    train                                   = 15,
    union                                   = 16,
    guard                                   = 17,
    lottery                                 = 19,
    rob_exp                                 = 20,
    depot                                   = 21,
    activity_pvp                            = 22,
    invite                                  = 23,
    battle                                  = 24,
    skin_shop                               = 25,
    room                                    = 26,
    union_battle                        = 27,
    dark                                    = 28,

    tavern_time_limit                   = 601,
    tavern_draw_card                = 602,
    tavern_rare_draw_card           = 603,
    tavern_depot_shop               = 604,
    tavern_depot_vip_shop           = 605,
    tavern_rare_shop                = 606,
    tavern_times_limit              = 607,
    tavern_diamond_shop         = 608,
    tavern_god_pump                 = 609,
}

_M.TrainType = 
{
    base                                    = 1,
    attack                                  = 2,
    defense                                 = 3,
    spell                                   = 4,
    strategy                                = 5,
    group                                   = 6
}

_M.UnionTechType = 
{
    lord                                    = 0,
    equip                                   = 1,
    hero                                    = 2
}

_M.UnionTechId =
{
    lord_reputation                         = 1,
    lord_tax                                = 2,
    lord_guard                              = 3,
    lord_hired                              = 4,
    lord_exp                                = 5,
    lord_yubi                               = 6
}

_M.UnionCampStatus = 
{
    na                                      = 1,
    scouted                                 = 2,
    defeated                                = 3,
}

_M.MsgType =
{
    world           = 1,
    bulletin        = 2,
    battle          = 3,
    union           = 4,
}

_M.FindMatchType =
{
    trophy          = 1,
    ladder          = 2,
    clash           = 3,
    hall            =4,
    union_battle     = 5,
    dark            = 6,
}

_M.RankRange =
{
    lord            = 1,
    union           = 2,
    region          = 3,
    dark            = 4,
}

_M.FindClashGrade =
{
    bronze          = 1,
    silver          = 2,
    gold            = 3,
    platinum        = 4,
    legend          = 5
}

_M.Privilege =
{
    chat_ban        = 0x0001,
    mail_free       = 0x0002,
}

_M.SkillQualityParam = {1, 1.44, 2.4336, 3.50438, 5.04631, 7.26669}
_M.SkillOutputParam = 0.88
_M.CardQualityParam = {1.44, 2.4336, 3.50438, 5.04631, 7.26669}
_M.Power2FightParam = 1
_M.Life2FightParam = 0.4

_M.ErrorType = 
{
    ok                                      = 0,
    error                                   = -32768,
    unknown                                 = -32767,
    timestamp_out_of_sync                   = -32766,
    ingot_out_of_sync                       = -32765,
    invalid_param                           = -32764,
    invalid_id                              = -32763,
    invalid_position                        = -32762,
    invalid_type                            = -32761,
    invalid_fixity_status                   = -32760,
    invalid_battle_status                   = -32759,
    need_more_ingot                         = -32758,
    need_more_gold                          = -32757,
    need_more_grain                         = -32756,
    need_more_orange_hero_f_box             = -32755,                          
    need_more_purple_hero_f_box             = -32753,    
    need_more_recruittoken                  = -32746,
    need_more_evolutematerial               = -32745,
    need_more_storage                       = -32744,
    need_more_samecard                      = -32743,
    need_more_daily_buy_gold                = -32742,
    need_more_daily_buy_grain               = -32741,
    achieve_level_out_of_sync               = -32740,
    achieve_cant_claim                      = -32739,
    card_need_evolution                     = -32738,
    card_already_max_level                  = -32737,
    card_not_support                        = -32736,
    card_contain_legend                     = -32735,
    claimed                                 = -32734,
    claim_not_support                       = -32733,
    card_evoluted                           = -32732,
    need_more_orange_horse_f_box            = -32731,
    need_more_purple_horse_f_box            = -32730,
    contain_guard_hero                      = -32729,
    
    leader_operate                          = -32728,
    elder_operate                           = -32727,    
    rookie_operate                          = -32725,
    union_operate                           = -32724,
    
    need_more_flag                          = -32723,
    
    card_cannot_compose                     = -32722,
    need_more_dust                          = -32721,
    need_more_stonerare                     = -32720,
    need_more_stonelegend                   = -32719,
    need_more_flowerrare                    = -32718,
    need_more_flowerlegend                  = -32717,
    card_in_troop                           = -32716,
    
    need_more_yubi                          = -32715,
    need_more_polish                        = -32714,
    
    union_elder_max                         = -32713, 
    need_more_union_gold                    = -32712,
    need_more_union_wood                    = -32711,
    need_more_union_act                     = -32710,
    need_more_union_tech_res                = -32709,
    more_than_union_level                   = -32708,    

    need_more_horse_shoes                   = -32707,
    need_more_horse_armor                   = -32706,
    need_more_exphorse                      = -32705,

    need_more_visit_prop                    = -32704,
    hero_leave                              = -32703,
    task_doing                              = -32702,

    need_more_exchange_res                  = -32701,

    union_level_max                     = -32700,

    fragment_not_enough             = -32699,
    compose_common_fragment   = -32698,
}

_M.Event = 
{
    application                             = "event_application",      -- do not change this name since used in LuaGame
    resource                                = "event_resource",

    market_list_dirty                       = "market list dirty",
    fragment_market_open                    = "fragment market open",
    fragment_market_closed                  = "fragment market closed",
    gift_open                               = "gift open",
    gift_closed                             = "gift closed",

    rank_list_dirty                         = "rank list dirty",
    server_bonus_list_dirty                 = "server bonus list dirty",
    
    card_dirty                              = "card dirty",
    card_add                                = "card add",
    card_select                             = "card select",
    card_list_dirty                         = "card list dirty",
    card_flag_dirty                         = "card flag dirty",
    
    hero_guard_dirty                        = "hero guard dirty",
    guard_confirm                           = "guard confirm",
    fragment_dirty                          = "fragment dirty",
    bonus_dirty                             = "bonus dirty",
    task_dirty                              = "task dirty",
    product_dirty                           = "product_dirty",
    prop_dirty                              = "prop dirty",
    refresh_count_dirty                     = "refresh count dirty",
    fund_task_dirty                         = "fund task dirty",
        
    gold_dirty                              = "gold dirty",
    grain_dirty                             = "grain dirty",
    ingot_dirty                             = "ingot dirty",
    ghost_dirty                             = "ghost dirty",
    blood_jade_dirty                        = "blood jade dirty",
    daily_active_dirty                      = "daily active dirty",

    union_battle_trophy_dirty                 = "union battle trophy dirty",
    
    fixity_dirty                            = "fixity dirty",
    achieve_list_dirty                      = "achieve list dirty",
    level_dirty                             = "level dirty",
    exp_dirty                               = "exp dirty",
    vip_dirty                               = "vip dirty",
    vip_exp_dirty                           = "vip exp dirty",
    trophy_dirty                            = "trophy dirty",
    dark_trophy_dirty                   = "dark trophy dirty",
    clash_trophy_dirty                      = "clash_trophy_dirty",
    name_dirty                              = "name dirty",
    icon_dirty                              = "icon dirty",
    avatar_image_dirty                      = "avatar image dirty",
    avatar_frame_dirty                      = "avatar frame dirty",
    crown_dirty                             = "crown_dirty",
    total_attack_dirty                      = "total attack dirty",
    total_defense_dirty                     = "total defense dirty",
    week_attack_dirty                       = "week attack dirty",
    week_defense_dirty                      = "week defense dirty",
    bind_gcid_dirty                         = "bind_gcid_dirty",
    
    user_dirty                              = "user dirty",
    change_name_dirty                       = "change name dirty",  
    character_dirty                         = "chracter dirty",
    
    friend                                  = "friend",
    mail                                    = "mail",
    message                                 = "message",

    log_dirty                               = "log dirty",
    log_shared                              = "log shared",
    pk_join                                 = "pk join",
    
    chapter_dirty                           = "chapter dirty",
    city_dirty                              = "city dirty",  
    city_user_dirty                         = "city user dirty",  
    chapter_level_dirty                     = "chapter level dirty",
    city_sweep                              = "city sweep",
        
    login                                   = "login",

    daily_gold_dirty                        = "daily gold dirty",
    recharge_success                        = "recharge_success",
    
    train_dirty                             = "train dirty",
    use_prop                                = "use prop",
    task_points_dirty                       = "task points dirty", 
    
    push_notice                             = "push notice",
    
    copy_times_dirty                        = "copy times dirty",

    hero_lottery                            = "hero lottery",
    mix_hero                                = "mix hero",
    split_hero                              = "split hero",

    time_hour_changed                       = "time hour changed",
    server_day_changed                      = "server day changed",
    server_hour_changed                     = "server hour changed",

    union_dirty                             = "union dirty",
    union_res_dirty                         = "union res dirty",
    union_search_dirty                      = "union search dirty",
    union_recommand_dirty                   = "union recommand dirty",
    union_list_dirty                        = "union list dirty",
    union_enter_dirty                       = "union create dirty",
    union_exit_dirty                        = "union destroy dirty",
    union_edit_dirty                        = "union edit dirty",
    union_hires_dirty                       = "union hires dirty",
    union_tech_dirty                        = "union tech dirty",
    union_tech_upgrade                      = "union tech upgrade",
    union_boss_dirty                        = "union boss dirty",
    union_member_dirty                      = "union member dirty",
    union_level_upgrade                     = "union level upgrade",
    union_fund_dirty                        = "union fund dirty",
    union_group_dirty                       = "union group dirty",

    union_battle_ready                      = "union battle ready",

    room_dirty                             = "room dirty",
    room_res_dirty                         = "room res dirty",
    room_list_dirty                        = "room list dirty",
    room_enter_dirty                       = "room create dirty",
    room_exit_dirty                        = "room destroy dirty",
    room_edit_dirty                        = "room edit dirty",

    invalid_tutorial                        = "invalid_tutorial",

    clash_sync_ready                        = "clash sync ready",
    
    invite_count_dirty                      = "invite count dirty",
    invite_ingot_dirty                      = "invite ingot dirty",
    invite_bonus_dirty                      = "invite bonus dirty",

    rematch_again                           = "rematch again",
    rematch_npc                             = "rematch npc",
    rematch_hide                            = "rematch hide",

    month_card_dirty                        = "month card dirty",
    package_dirty                           = "package dirty",
    fund_dirty                              = "fund dirty",

    invalid_input                           = "invalid_input",

    group_cards_dirty                    = "group cards dirty",
    recommend_troop_dirty           = "recommend troop dirty",
}

_M.BattleType = 
{
    base_PVE                = 1,
    base_PVP                = 2,
    base_replay             = 3,
    base_guidance           = 4,
    base_test               = 10,
        
    base_type               = 100,
    
    task                    = 101,      
    
    expedition_ex           = 151,
    expedition_ex_boss      = 152,
    
    PVP_clash               = 211,
    PVP_clash_npc           = 212,
    PVP_ladder              = 213,
    PVP_ladder_npc          = 214,
    
    PVP_friend              = 221,        
    PVP_room                = 241,
    PVP_group               = 242,
    PVP_dark                = 243,
    
    replay                  = 301,
    
    guidance                = 401,
    
    test                    = 1001,
    
    unittest                = 2001,
    layout                  = 2002,
    teach                   = 2003,
    recommend_train         = 2004,
}

_M.BattleSceneType = 
{
    country_scene_wei       = 1,
    country_scene_shu       = 2,
    country_scene_wu        = 3,
    country_scene_qun       = 4,
    exp_scene               = 5,
    horse_scene             = 6,
    gold_scene              = 7,
    toad_scene              = 8,
    union_scene             = 9,
    reserve                 = 10,

    clash_bronze            = 11,
    clash_silver            = 12,
    clash_gold              = 13,
    clash_platinum          = 14,
    clash_diamond           = 15,
    clash_legend            = 16,

    ladder_1                = 21,

    count                   = 21
}

_M.TeachType = {
    basic_teach          = 1,
    mid_teach            = 2,
    master_teach         = 3,
    new_teach            = 4,

    count                = 4,
}

_M.BattleResult = 
{
    lose                    = -1,
    draw                    = 0,
    win                     = 1
}

_M.TroopIndex = 
{
    normal                  = 1,
    union_battle1           = 101,
    union_battle2           = 102,
    union_battle3           = 103,
    union_battle4           = 104,
    union_battle5           = 105,
    dark_battle1            = 111,
    dark_battle2            = 112,
    dark_battle3            = 113,
    
    num                     = 100
}

_M.RecommendTroop = 
{
    system                  = 1,
    player                  = 2,
}

_M.UnlockGuideType =
{
    expedition                  = 6,
    find_match                  = 7,

    rob_exp                     = 9,
    market                      = 10,
    
    rob_gold                    = 12,
    guard                       = 13,
    rob_horse                   = 14,
    union                       = 15,
    
    ladder                      = 19,
}

_M.MarketBuyType =
{
    --fragment                    = 1,
    vip                         = 1,
    daily                       = 2,
    random                      = 3,
    --flag                        = 4,
    union                       = 4,
    dragon_flag                 = 5
}

_M.UnionJoinType =
{
    any                         = 1,
    apply                       = 2,
    close                       = 3
}

_M.UnionJob = 
{
    rookie                      = 1,    
    elder                       = 2,
    leader                      = 3
}

_M.RoomJob = 
{
    rookie                      = 1,    
    elder                       = 2,
    leader                      = 3
}

_M.GroupJob = 
{
    rookie                      = 1,    
    elder                       = 2,
    leader                      = 3
}

_M.AggregateType = 
{
    sum                         = 1,
    max                         = 2,
    min                         = 3,
    table                       = 4,
}

_M.CharacterNames = {[2] = 'haima', [3] = 'youxi', [4] = 'kongquewu', [5] = 'chengzhinei', [12] = 'yixisi', [13] = 'moliangliao', [10] = 'longqi', [51] = 'youchengshidai'}

function _M.parseData(name, data)
    if name == "global.bin" then _M._globalInfo = dataparser.parseData(data, false)
    elseif name == "monster.bin" then _M._monsterInfo = dataparser.parseData(data, true)
    elseif name == "skill.bin" then _M._skillInfo = dataparser.parseData(data, true)
    elseif name == "fixity.bin" then _M._fixityInfo = dataparser.parseData(data, true)
    elseif name == "bonus.bin" then _M._bonusInfo = dataparser.parseData(data, true)
    elseif name == "task.bin" then _M._taskInfo = dataparser.parseData(data, true)
    elseif name == "props.bin" then _M._propsInfo = dataparser.parseData(data, true)
    elseif name == "res.bin" then _M._resInfo = dataparser.parseData(data, true)
    elseif name == "products.bin" then _M._productsInfo = dataparser.parseData(data, true)
    elseif name == "products_ex.bin" then _M._productsExInfo = dataparser.parseData(data, true)
    elseif name == "union_products_ex.bin" then _M._unionProductsExInfo = dataparser.parseData(data, true)
    elseif name == "rare_products.bin" then _M._rareProductsInfo = dataparser.parseData(data, true)
    elseif name == "diamond_products.bin" then _M._diamondProductsInfo = dataparser.parseData(data, true)
    elseif name == "goods.bin" then _M._goodsInfo = dataparser.parseData(data, true)
    elseif name == "drop.bin" then 
        _M._dropInfo = dataparser.parseData(data, true)
        _M._recruitInfo = {}
        for k, v in pairs(_M._dropInfo) do
            if (v._type == 1001 or v._type == 1002 or v._type == 1011 or v._type == 1012 or v._type == 1013 or v._type == 1014) and v._value ~= 10100 and v._value ~= 10101 then
                _M._recruitInfo[v._value] = v
            end
        end
    elseif name == "guide.bin" then _M._guideInfo = dataparser.parseData(data, true)
    elseif name == "guidance.bin" then _M._guidanceInfo = dataparser.parseData(data, true)    
    elseif name == "chapter.bin" then _M._chapterInfo = dataparser.parseData(data, true)
    elseif name == "level.bin" then _M._levelInfo = dataparser.parseData(data, true)    
    elseif name == "story.bin" then _M._storyInfo = dataparser.parseData(data, true)
    elseif name == "help.bin" then _M._helpInfo = dataparser.parseData(data, true)
    elseif name == "tip.bin" then _M._tipInfo = dataparser.parseData(data, true)
    elseif name == "troop.bin" then _M._troopInfo = dataparser.parseData(data, true)
    elseif name == "particle.bin" then  _M._particleInfo = dataparser.parseData(data, true)
    elseif name == "hero_audio.bin" then  _M._heroAudioInfo = dataparser.parseData(data, true)
    elseif name == "skill_audio.bin" then  _M._skillAudioInfo = dataparser.parseData(data, true)
    elseif name == "condition.bin" then _M._conditionInfo = dataparser.parseData(data, true)
    elseif name == "event.bin" then
        _M._eventInfo = dataparser.parseData(data, true)
        
        -- Convert json string to table array
        for k, v in pairs(_M._eventInfo) do
            --lc.log(v._effectValue)
            local val = json.decode(v._effectValue)
            v._effectValue = (#val > 0 and val or {val})
        end
    elseif name == "activity.bin" then _M._activityInfo = dataparser.parseData(data, true)
    elseif name == "activity_new.bin" then _M._activityNewInfo = dataparser.parseData(data, true)
    elseif name == "activity_goods.bin" then _M._activityGoodsInfo = dataparser.parseData(data, true)
    elseif name == "pvp_chat.bin" then _M._pvpChatInfo = dataparser.parseData(data, true)    
    elseif name == "pvp_products.bin" then _M._pvpProductsInfo = dataparser.parseData(data, true)  
    elseif name == "about.bin" then _M._aboutInfo = dataparser.parseData(data, true)
    elseif name == "rank_bonus.bin" then _M._rankBonusInfo = dataparser.parseData(data, true)
    elseif name == "main_task.bin" then _M._mainTaskInfo = dataparser.parseData(data, true)    
    elseif name == "union_products.bin" then _M._unionProductsInfo = dataparser.parseData(data, true)
    elseif name == "union_tech.bin" then _M._unionTechInfo = dataparser.parseData(data, true)
    elseif name == "copy.bin" then _M._copyInfo = dataparser.parseData(data, true)
    elseif name == "activity_task.bin" then
        _M._activityTaskInfo = dataparser.parseData(data, true)

        -- Get special task reference
        for k, v in pairs(_M._activityTaskInfo) do
            if v._type == _M.ActivityTaskType.pvp then
                _M._activityTaskInfo._pvp = v
            end
        end

    elseif name == "month_checkin.bin" then _M._monthCheckinInfo = dataparser.parseData(data, true)
    elseif name == "month_hero.bin" then _M._monthHeroInfo = dataparser.parseData(data, true)
    elseif name == "magic.bin" then _M._magicInfo = dataparser.parseData(data, true)
    elseif name == "trap.bin" then _M._trapInfo = dataparser.parseData(data, true)
    elseif name == "ladder.bin" then _M._ladderInfo = dataparser.parseData(data, true)
    elseif name == "ladder_chests.bin" then _M._ladderChestsInfo = dataparser.parseData(data, true)
    elseif name == "ladder_products.bin" then _M._ladderProductsInfo = dataparser.parseData(data, true)
    elseif name == "ladder_rank.bin" then _M._ladderRankInfo = dataparser.parseData(data, true)
    elseif name == "character.bin" then _M._characterInfo = dataparser.parseData(data, true)
    elseif name == "character_info.bin" then _M._characterDescInfo = dataparser.parseData(data, true)
    elseif name == "teach.bin" then _M._teachInfo = dataparser.parseData(data, true)
    elseif name == "skin.bin" then _M._skinInfo = dataparser.parseData(data, true)
    elseif name == "exchange.bin" then _M._exchangeInfo = dataparser.parseData(data, true)
    end
end

function _M.parseTeach(name, data)
    if string.hasSuffix(name, '.bin') then
        local prefix = string.sub(name, 1, -5)
        local index = tonumber(prefix)
        if index ~= nil then
            local n, serial  = string.unpack(string.sub(data, 7, #data), '<i')
            _M._teachYgoInfo = _M._teachYgoInfo or {}
            _M._teachYgoInfo[index] = string.decrypt(string.sub(data, 11, #data), serial)
        end
    end
end

function _M.isUnionRes(infoId)
    return infoId == _M.ResType.union_gold or infoId == _M.ResType.union_wood or infoId == _M.ResType.union_act
end

function _M.isCardBack(infoId)
    return infoId >= Data.PropsId.card_back and infoId < Data.PropsId.card_back + 100
end

function _M.isAvatarFrame(infoId)
    return infoId >= Data.PropsId.avatar_frame and infoId < Data.PropsId.avatar_frame + 100
end

function _M.getType(infoId)
    if infoId == 0 then
        return Data.CardType.fortress
    elseif infoId < 100 then
        return Data.CardType.res
    elseif infoId < 4000 then
        return math.floor(infoId / Data.INFO_ID_GROUP_SIZE) + 10
    elseif infoId < Data.INFO_ID_GROUP_SIZE_LARGE then
        return math.floor(infoId / Data.INFO_ID_GROUP_SIZE)
    elseif infoId < Data.INFO_ID_FRAGMENT_SIZE_LARGE then
        local type = math.floor(infoId / Data.INFO_ID_GROUP_SIZE_LARGE)
        if type == Data.CardType.monster_ex then type = Data.CardType.monster end
        return type
    else
        return Data.CardType.fragment
    end
end

function _M.getSkillType(skillId)
    if skillId >= 20000 then return 9 end
    return math.floor(skillId / Data.INFO_ID_GROUP_SIZE)
end

function _M.hasBigCard(infoId)
    local type = _M.getType(infoId)
    return type >= _M.CardType.monster and type <= _M.CardType.trap
end

function _M.isUserVisible(infoId)
    local info = _M.getInfo(infoId)
    return info._isHide == 0 or (info._isHide == 2 and ClientData.isDEV())
end

function _M.getInfo(id)
    local type = _M.getType(id)
    if type == _M.CardType.fragment then
        id = P._playerCard:convert2CardId(id)
    end
    if type == _M.CardType.res then
        return _M._resInfo[id], type
    elseif type == _M.CardType.monster then
        return _M._monsterInfo[id], type
    elseif type == _M.CardType.magic then
        return _M._magicInfo[id], type
    elseif type == _M.CardType.trap then
        return _M._trapInfo[id], type
    elseif type == _M.CardType.props then
        return _M._propsInfo[id], type
    elseif type == _M.CardType.other or type == _M.CardType.nature or type == _M.CardType.category or type == _M.CardType.keyword then
        return nil, type
    else
        return nil
    end
end

function _M.getOriginId(id)
    local originId =  Data.getInfo(id)._originId 
    if originId == nil or originId == 0 then originId = id end
    return originId
end

function _M.getSceneTypeByCityId(cityId)
    return Data.BattleSceneType.country_scene_wei
end

function _M.getPackages(infoId)
    local infos = {}
    local info = Data.getInfo(infoId)
    for i = 1, #info._packageId do
        if info._packageId[i] == 0 then break end
        for k, v in pairs(Data._recruitInfo) do
            if v._value == info._packageId[i] then
                infos[i] = v
                break
            end
        end
    end
    return infos
end

function _M.pb2Resource(pbResource)
    return {_infoId = pbResource.info_id, _num = pbResource.num}
end

function _M.isLevelLock(levelId)
    local levelInfo = Data._levelInfo[levelId]
    local difficulty = math.floor(levelId / 10000)

    if levelId > P._playerWorld._curLevel[difficulty] then return true end
    if (difficulty > 1 and levelId % 10000 == 101) then 
        difficulty = difficulty - 1
        levelId = levelInfo._passId[1]
        return levelId >= P._playerWorld._curLevel[difficulty] 
    end

    return false
end

function _M.isLevelPass(levelId)
    local levelInfo = Data._levelInfo[levelId]
    local difficulty = math.floor(levelId / 10000)

    return levelId < P._playerWorld._curLevel[difficulty]
end

function _M.getRecruiteInfo(infoValue)
    for k, v in pairs(Data._recruitInfo) do
        if v._value == infoValue then return v end
    end
end

function _M.getIsRareRecruite(info)
    return info._value > 100000 and info._value < 200000
end

function _M.getIsCharacterRecruite(info)
    return info._value > 10200 and info._value < 100000
end

function _M.getIsTimeLimitRecruite(info)
    return info._value > 200000 and info._value < 250000
end

function _M.getIsTimeLimitRoleRecruite(info)
    return info._value >= 205001 and info._value < 212001
end

function _M.getIsTimesLimitRecruite(info)
    return info._value > 250000 and info._value < 260000
end

function _M.getIsGodPumpRecruite(info)
    return info._value > 260000
end

function _M.isNormalTroop(index)
    return index < _M.TroopIndex.num
end

function _M.isUnionBattleTroop(index)
    return index >= _M.TroopIndex.union_battle1 and index <= _M.TroopIndex.union_battle5
end

function _M.isDarkTroop(index)
    return index >= _M.TroopIndex.dark_battle1 and index <= _M.TroopIndex.dark_battle3
end

Data = _M