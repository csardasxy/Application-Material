using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// item information's database in game
/// </summary>

public class itemdb : MonoBehaviour {

    public List<item> items = new List<item>();
    //属性编号 0：HP 1：现HP 2：MP 3：现MP 
    //4：攻击力 5：防御力 6：命中 7：暴击 8：闪避 9：格挡
    void Start()
    {
        //护甲1
        items.Add(new item("col_icon_armor1", 0, "拉格朗日之甲", "增加50防御力\n", 1,
            item.ItemType.Armor3));
        items[0].addProperty(5, 50);
        items[0].addHistory("如果没有意外，莫利和卢娅早在三年之前就已经成婚了。那个意外便是卢娅的父亲—西塞家族卫队长凯林。虽然莫利和卢娅青梅竹马，但凯林并不喜欢这位从小养尊处优，没经历过磨难的公子哥。莫利12岁在家族之战的表现使这位沙场宿将对他的看法大大改观，也正因此在长老要求卢娅嫁给莫利时凯林并未横加阻拦。莫利离家前，这位素来不露感情的卫队长，竟破天荒亲自摘下自己的铠甲给莫利穿上，并发誓莫利一日不归，他一日不着新铠。");
        items[0].addUp("col_icon_armor1-2", "col_icon_material1", 2);
        items[0].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_armor1-2", 1, "不羁拉格朗日", "增加100防御力\n", 1,
            item.ItemType.Armor3));
        items[1].addProperty(5, 100);
		items[1].addHistory ("如果没有意外，莫利和卢娅早在三年之前就已经成婚了。那个意外便是卢娅的父亲—西塞家族卫队长凯林。虽然莫利和卢娅青梅竹马，但凯林并不喜欢这位从小养尊处优，没经历过磨难的公子哥。莫利12岁在家族之战的表现使这位沙场宿将对他的看法大大改观，也正因此在长老要求卢娅嫁给莫利时凯林并未横加阻拦。莫利离家前，这位素来不露感情的卫队长，竟破天荒亲自摘下自己的铠甲给莫利穿上，并发誓莫利一日不归，他一日不着新铠。\n此甲经制甲大师斯沃顿重铸，加入白凌锭，开肃杀之气，磨灭凯林旧迹，如新铠临世，重焕不羁之势。");
        items[1].addUp("col_icon_armor1-3", "col_icon_material1", 2);
        items[1].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_armor1-3", 2, "归释拉格朗日", "增加200防御力\n", 1,
            item.ItemType.Armor3));
        items[2].addProperty(5, 200);
		items[2].addHistory("如果没有意外，莫利和卢娅早在三年之前就已经成婚了。那个意外便是卢娅的父亲—西塞家族卫队长凯林。虽然莫利和卢娅青梅竹马，但凯林并不喜欢这位从小养尊处优，没经历过磨难的公子哥。莫利12岁在家族之战的表现使这位沙场宿将对他的看法大大改观，也正因此在长老要求卢娅嫁给莫利时凯林并未横加阻拦。莫利离家前，这位素来不露感情的卫队长，竟破天荒亲自摘下自己的铠甲给莫利穿上，并发誓莫利一日不归，他一日不着新铠。\n此甲经制甲大师斯沃顿重铸，加入白凌锭，开肃杀之气，磨灭凯林旧迹，如新铠临世，重焕不羁之势。\n莫利离家10年后，凯林于第二次家族之战中被杀，神匠赫菲斯托斯取凯林遗体，与拉格朗日之甲相融，取名归释，愿凯林之魂永伴西塞一脉。");
        //护甲2
        items.Add(new item("col_icon_armor2", 3, "护甲", "增加100防御力\n增加50闪避", 1,
            item.ItemType.Armor3));
        items[3].addProperty(5, 100);
        items[3].addProperty(8, 50);
        items[3].addUp("col_icon_armor2-2", "col_icon_material1", 2);
        items[3].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_armor2-2", 4, "护甲", "增加200防御力\n增加100闪避", 1,
            item.ItemType.Armor3));
        items[4].addProperty(5, 200);
        items[4].addProperty(8, 100);
        items[4].addUp("col_icon_armor2-3", "col_icon_material1", 2);
        items[4].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_armor2-3", 5, "护甲", "增加300防御力\n增加150闪避", 1,
            item.ItemType.Armor3));
        items[5].addProperty(5, 300);
        items[5].addProperty(8, 150);
        //护甲3
        items.Add(new item("col_icon_armor3", 6, "护甲", "增加100防御力\n增加50格挡", 1,
            item.ItemType.Armor3));
        items[6].addProperty(5, 100);
        items[6].addProperty(9, 50);
        items[6].addUp("col_icon_armor2-2", "col_icon_material1", 2);
        items[6].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_armor3-2", 7, "护甲", "增加200防御力\n增加100格挡", 1,
            item.ItemType.Armor3));
        items[7].addProperty(5, 200);
        items[7].addProperty(9, 100);
        items[7].addUp("col_icon_armor3-3", "col_icon_material1", 2);
        items[7].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_armor3-3", 8, "护甲", "增加300防御力\n增加150格挡", 1,
            item.ItemType.Armor3));
        items[8].addProperty(5, 300);
        items[8].addProperty(9, 150);
        //头盔1
        items.Add(new item("col_icon_head", 9, "洛比达之盔", "增加50防御力\n", 1,
            item.ItemType.Hat1));
        items[9].addProperty(5, 50);
		items[9].addHistory("帕米尔历729年，敌对家族卡诺家族进攻西塞家族。面对强大的攻势，没有准备的西塞家族几乎没有取胜的希望。而当时，年仅12岁的莫利，披戴训练盔甲的莫利，悍然冲到了战斗的第一线，并依靠平日训练的技巧杀死了两个卡诺家族的成年战士，极大鼓舞了西塞家族的士气，凭一己之力，扭转了战斗局势，使西塞家族幸免于难。他现在头上的这顶洛必达之盔，就属于被他杀死的两个卡诺家族的战士中的其中一个，同时也是卡诺家族长老之子，以此纪念他战斗之路的开始。");
        //头盔2
        items.Add(new item("col_icon_head2", 10, "头盔", "增加100防御力", 1,
            item.ItemType.Hat1));
        items[10].addProperty(5, 100);
        //头盔3
        items.Add(new item("col_icon_head3", 11, "头盔", "增加200防御力", 1,
            item.ItemType.Hat1));
        items[11].addProperty(5, 200);
        //盾1
        items.Add(new item("col_icon_shield1", 12, "柯西之盾", "增加200防御力\n", 1,
            item.ItemType.Shield2));
        items[12].addProperty(5, 200);
		items [12].addHistory ("莫利的母亲米兰达，莫利父亲纳尔的表妹，在未与纳尔结婚前爱着另一个人，一个她永远无法与之在一起的人—冥将军卢卡斯。在卢卡斯尚未成为冥将军之前，米兰达陪着他从一个一文不名的小子成长为威名赫赫的一方霸主，然而，在他们即将成婚的前夕，卢卡斯离开了她，不知去处，只留下了伴他征战良久的一面名为柯西的盾牌。在米兰达返回西塞家族的第二年，便传来卢卡斯成为将军的消息，心死的米兰达顺长老的意愿嫁给了表哥纳尔，并在次年生下莫利。因此，米兰达赠与莫利的这面柯西之盾，不仅是想保护她将死未死的挚子，也是纪念她实亡未亡的旧爱。");
        items[12].addUp("col_icon_shield1-2", "col_icon_material1", 2);
        items[12].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_shield1-2", 13, "怜悯柯西", "增加200防御力\n", 1,
            item.ItemType.Shield2));
        items[13].addProperty(5, 100);
		items [13].addHistory ("莫利的母亲米兰达，莫利父亲纳尔的表妹，在未与纳尔结婚前爱着另一个人，一个她永远无法与之在一起的人—冥将军卢卡斯。在卢卡斯尚未成为冥将军之前，米兰达陪着他从一个一文不名的小子成长为威名赫赫的一方霸主，然而，在他们即将成婚的前夕，卢卡斯离开了她，不知去处，只留下了伴他征战良久的一面名为柯西的盾牌。在米兰达返回西塞家族的第二年，便传来卢卡斯成为将军的消息，心死的米兰达顺长老的意愿嫁给了表哥纳尔，并在次年生下莫利。因此，米兰达赠与莫利的这面柯西之盾，不仅是想保护她将死未死的挚子，也是纪念她实亡未亡的旧爱。\n莫利终究是得知了母亲的故事，然而此时弱小的他，不知道该为母亲做些什么，他不知道母亲还爱不爱那个混蛋，更不知道自己能不能战胜他，他只能祈求斯沃顿改造这面盾牌以遮盖卢卡斯的痕迹，从此此盾与卢卡斯无关。此盾的主人，现在叫西塞！");
        items[13].addUp("col_icon_shield1-3", "col_icon_material1", 2);
        items[13].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_shield1-3", 14, "裁决柯西", "增加300防御力\n", 1,
            item.ItemType.Shield2));
        items[14].addProperty(5, 300);
		items [14].addHistory ("莫利的母亲米兰达，莫利父亲纳尔的表妹，在未与纳尔结婚前爱着另一个人，一个她永远无法与之在一起的人—冥将军卢卡斯。在卢卡斯尚未成为冥将军之前，米兰达陪着他从一个一文不名的小子成长为威名赫赫的一方霸主，然而，在他们即将成婚的前夕，卢卡斯离开了她，不知去处，只留下了伴他征战良久的一面名为柯西的盾牌。在米兰达返回西塞家族的第二年，便传来卢卡斯成为将军的消息，心死的米兰达顺长老的意愿嫁给了表哥纳尔，并在次年生下莫利。因此，米兰达赠与莫利的这面柯西之盾，不仅是想保护她将死未死的挚子，也是纪念她实亡未亡的旧爱。\n莫利终究是得知了母亲的故事，然而此时弱小的他，不知道该为母亲做些什么，他不知道母亲还爱不爱那个混蛋，更不知道自己能不能战胜他，他只能祈求斯沃顿改造这面盾牌以遮盖卢卡斯的痕迹，从此此盾与卢卡斯无关。此盾的主人，现在叫西塞！\n经再次改造，曾经的柯西之盾如今已成为可挡一切冷锋的无敌之盾，卢卡斯，接受裁决的时候到了。");
        //盾2
        items.Add(new item("col_icon_shield2", 15, "塞萨尔", "增加200防御力\n", 1,
            item.ItemType.Shield2));
        items[15].addProperty(5, 200);
		items [15].addHistory ("传闻遗迹之城原为一天然石阵，由工匠之神伏尔甘寻得并雕成碑林，碑灵化为庇护法阵，凡间器物若入法阵可获祝福之力。后伏尔甘遗其刻刀于碑林中。\n帕米尔历32年，赫尔尼误入遗迹之城，得刻刀，炼为重盾，取丧弟塞萨尔之名。凭此无刃可破之盾，赫尔尼威名远扬，得先王赏识，任天将军，治帕米尔王城。");
        items[15].addUp("col_icon_shield1-2", "col_icon_material1", 2);
        items[15].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_shield2-2", 16, "赫尼塞萨尔", "增加200防御力\n增加50格挡\n", 1,
            item.ItemType.Shield2));
        items[16].addProperty(5, 200);
        items[16].addProperty(9, 50);
		items [16].addHistory ("传闻遗迹之城原为一天然石阵，由工匠之神伏尔甘寻得并雕成碑林，碑灵化为庇护法阵，凡间器物若入法阵可获祝福之力。后伏尔甘遗其刻刀于碑林中。\n帕米尔历32年，赫尔尼误入遗迹之城，得刻刀，炼为重盾，取丧弟塞萨尔之名。凭此无刃可破之盾，赫尔尼威名远扬，得先王赏识，任天将军，治帕米尔王城。\n'能回到曾经在赫尔尼手中的样子真是太好了，我是多么热爱他啊，或许，再也找不到比他更好的主人了。'");
        items[16].addUp("col_icon_shield2-3", "col_icon_material1", 2);
        items[16].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_shield2-3", 17, "伏甘塞萨尔", "增加300防御力\n增加100格挡\n", 1,
            item.ItemType.Shield2));
        items[17].addProperty(5, 300);
        items[17].addProperty(9, 300);
		items [17].addHistory ("传闻遗迹之城原为一天然石阵，由工匠之神伏尔甘寻得并雕成碑林，碑灵化为庇护法阵，凡间器物若入法阵可获祝福之力。后伏尔甘遗其刻刀于碑林中。\n帕米尔历32年，赫尔尼误入遗迹之城，得刻刀，炼为重盾，取丧弟塞萨尔之名。凭此无刃可破之盾，赫尔尼威名远扬，得先王赏识，任天将军，治帕米尔王城。\n'能回到曾经在赫尔尼手中的样子真是太好了，我是多么热爱他啊，或许，再也找不到比他更好的主人了。'\n'我还记得你，伏尔甘，我们又要去雕琢美丽的遗迹之城了吗？真是太好了，我永远也不要再做那造了无数杀孽的魔盾了啊。'");

        //剑1
        items.Add(new item("col_icon_sword1", 18, "罗尔之剑", "增加200攻击力\n", 1,
            item.ItemType.Weapon0));
        items[18].addProperty(4, 200);
		items [18].addHistory ("西塞家族最顶尖的铸剑师洛里斯为他最喜欢的年轻人莫利·西塞铸造的一把利剑，也是其平生最得意之作。这把本应凝聚着光辉与荣耀的胜利之剑，因莫利的身份而面貌全非。当得知莫利必须跟随父辈的脚步永远离开家族时，洛里斯重铸了曾用绿松石与赤莹铁打造的圣西塞之剑，融入黑曜石与铁树皮，伴以远古揉剑法，制成新剑罗尔，寓意此剑居黑白之际，阳冥之间，只要世间还有正恶之分，此剑便会永伴莫利左右。");
        items[18].addUp("col_icon_sword1-2", "col_icon_material1", 2);
        items[18].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_sword1-2", 19, "恐怖罗尔", "增加300攻击力\n", 1,
            item.ItemType.Weapon0));
        items[19].addProperty(4, 300);
		items [19].addHistory ("西塞家族最顶尖的铸剑师洛里斯为他最喜欢的年轻人莫利·西塞铸造的一把利剑，也是其平生最得意之作。这把本应凝聚着光辉与荣耀的胜利之剑，因莫利的身份而面貌全非。当得知莫利必须跟随父辈的脚步永远离开家族时，洛里斯重铸了曾用绿松石与赤莹铁打造的圣西塞之剑，融入黑曜石与铁树皮，伴以远古揉剑法，制成新剑罗尔，寓意此剑居黑白之际，阳冥之间，只要世间还有正恶之分，此剑便会永伴莫利左右。\n洛里斯对家族的怨念，终究还是融进了罗尔剑里。新一轮的重铸，果然还是激发了那积郁已久的怨念，如今这把黑白撕裂之剑将彻底沦为杀戮的魔剑，恐怖罗尔将毁灭一切。");
        items[19].addUp("col_icon_sword1-2", "col_icon_material1", 2);
        items[19].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_sword1-3", 20, "光辉罗尔", "增加500攻击力\n", 1,
            item.ItemType.Weapon0));
        items[20].addProperty(4, 500);
		items [20].addHistory ("西塞家族最顶尖的铸剑师洛里斯为他最喜欢的年轻人莫利·西塞铸造的一把利剑，也是其平生最得意之作。这把本应凝聚着光辉与荣耀的胜利之剑，因莫利的身份而面貌全非。当得知莫利必须跟随父辈的脚步永远离开家族时，洛里斯重铸了曾用绿松石与赤莹铁打造的圣西塞之剑，融入黑曜石与铁树皮，伴以远古揉剑法，制成新剑罗尔，寓意此剑居黑白之际，阳冥之间，只要世间还有正恶之分，此剑便会永伴莫利左右。\n洛里斯对家族的怨念，终究还是融进了罗尔剑里。新一轮的重铸，果然还是激发了那积郁已久的怨念，如今这把黑白撕裂之剑将彻底沦为杀戮的魔剑，恐怖罗尔将毁灭一切。\n莫利当然怨恨家族，但他不会像洛里斯一样，西塞一脉不是沉沦的恶魔，而是永耀世间的圣光！既然对那个腐朽的家族不再留恋，那便创造我西塞自己的传奇，我要这王朝，这世界，都向我俯首！");
        //剑2
        items.Add(new item("col_icon_sword2", 21, "达摩克里斯", "增加200攻击力\n增加50暴击\n", 1,
            item.ItemType.Weapon0));
        items[21].addProperty(4, 200);
        items[21].addProperty(7, 50);
		items [21].addHistory ("达摩克里斯本是先王爱剑，帕米尔历709年，先王察觉冥将军卢卡斯欲反，于宫中设宴，用马鬃倒悬爱剑于卢卡斯头顶，卢卡斯惊惧，立誓永忠于先王，先王令其治王国中部沃野，并赐此剑，名达摩克里斯。");
        items[21].addUp("col_icon_sword2-2", "col_icon_material1", 2);
        items[21].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_sword2-2", 22, "祈·达摩克里斯", "增加300攻击力\n增加100暴击\n", 1,
            item.ItemType.Weapon0));
        items[22].addProperty(4, 300);
        items[22].addProperty(7, 100);
		items [22].addHistory ("达摩克里斯本是先王爱剑，帕米尔历709年，先王察觉冥将军卢卡斯欲反，于宫中设宴，用马鬃倒悬爱剑于卢卡斯头顶，卢卡斯惊惧，立誓永忠于先王，先王令其治王国中部沃野，并赐此剑，名达摩克里斯。\n天之骄子卢卡斯，也许再也没人能理解他背后的酸楚了。'帕米尔，你毁我家族，断我生路，迫我为奴，你会付出代价的！'");
        items[22].addUp("col_icon_sword2-2", "col_icon_material1", 2);
        items[22].addUpExtra(0, "col_icon_material2", 1);

        items.Add(new item("col_icon_sword2-3", 23, "禁·达摩克里斯", "增加500攻击力\n增加200暴击\n", 1,
            item.ItemType.Weapon0));
        items[23].addProperty(4, 500);
        items[23].addProperty(7, 200);
		items [23].addHistory ("达摩克里斯本是先王爱剑，帕米尔历709年，先王察觉冥将军卢卡斯欲反，于宫中设宴，用马鬃倒悬爱剑于卢卡斯头顶，卢卡斯惊惧，立誓永忠于先王，先王令其治王国中部沃野，并赐此剑，名达摩克里斯。\n天之骄子卢卡斯，也许再也没人能理解他背后的酸楚了。'帕米尔，你毁我家族，断我生路，迫我为奴，你会付出代价的！'\n禁忌开启。");


        items.Add(new item("col_icon_potion1_atk+", 24, "血药", "增加100生命值", 99,
            item.ItemType.Potion));
        items[24].addProperty(1, 100);

        items.Add(new item("col_icon_potion1_atk++", 25, "血药", "增加100生命值", 99,
            item.ItemType.Potion));
        items[25].addProperty(1, 100);

        items.Add(new item("col_icon_potion1_def+", 26, "血药", "增加100生命值", 99,
            item.ItemType.Potion));
        items[26].addProperty(1, 100);

        items.Add(new item("col_icon_potion1_def++", 27, "血药", "增加100生命值", 99,
            item.ItemType.Potion));
        items[27].addProperty(1, 100);

        items.Add(new item("col_icon_potion1_invisible", 28, "血药", "增加100生命值", 99,
            item.ItemType.Potion));
        items[28].addProperty(1, 100);

        items.Add(new item("col_icon_potion1_invisible+", 29, "血药", "增加100生命值", 99,
            item.ItemType.Potion));
        items[29].addProperty(1, 100);

       

        items.Add(new item("col_icon_material1", 30, "乌寒木柄", "材料", 99,
            item.ItemType.Material));


        items.Add(new item("col_icon_material1-2", 31, "菱锌石", "材料", 99,
            item.ItemType.Material));


        items.Add(new item("col_icon_material1-3", 32, "碧嵩玉", "材料", 99,
            item.ItemType.Material));


        items.Add(new item("col_icon_material2", 33, "崇黎木", "材料", 99,
            item.ItemType.Material));


        items.Add(new item("col_icon_material2-2", 34, "花卢铅", "材料", 99,
            item.ItemType.Material));


        items.Add(new item("col_icon_material62-3", 35, "怜癸钢", "材料", 99,
            item.ItemType.Material));


        items.Add(new item("col_icon_material3", 36, "白凌锭", "材料", 99,
            item.ItemType.Material));


        items.Add(new item("col_icon_material3-2", 37, "青牛皮", "材料", 99,
            item.ItemType.Material));


        items.Add(new item("col_icon_material3-3", 38, "汐崖铁", "材料", 99,
            item.ItemType.Material));

    }

    public item finditem(int id)
    {
        for (int i = 0; i < items.Count; i++)
        {
            if (items[i].itemID == id)
                return items[i];
        }
        return null;
    }

    public item finditem(string name)
    {
        for (int i = 0; i < items.Count; i++)
        {
            if (items[i].itemName == name)
                return items[i];
        }
        return null;
    }
}
