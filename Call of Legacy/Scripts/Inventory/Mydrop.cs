using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// This controls the logic of item's drag & drop action
/// </summary>

public class Mydrop : UIDragDropItem {

    public bool showTooltip;//on/off the tips
    public GameObject Tooltip;// tips
    public List<item> itemlist;// item data
    public List<item> itemlist1;//item data
    public List<item> itemlist2;//item data
    public List<item> equiplist;// equipment daya
    public itemdb database;
    public GameObject introduce;// introduce window of each item
    public GameObject equipup;//
    public GameObject isdelete;// the check window of delete action
    public GameObject UpPosition;// inventory window's position
    public Bag bag;
    public Up up;
    public items0 item0;
    public items1 item1;
    public items2 item2;
    private int depth1,depth2;//dragable item's depth
    private Color color;//the name text's color of items for upgrade
    
	// Use this for initialization
	void Start () {
        bag = GameObject.Find("Bag").GetComponent<Bag>();
        up = GameObject.Find("EquipUP").GetComponent<Up>();
        database = GameObject.Find("itemdb").GetComponent<itemdb>();
        introduce = GameObject.Find("Introduce");
        equipup = GameObject.Find("EquipUP");
        isdelete = GameObject.Find("isdelete");
        UpPosition = GameObject.Find("UpPosition");
        itemlist = bag.equiplist;
        itemlist1 = bag.potionlist;
        itemlist2 = bag.materiallist;
        equiplist = GameObject.FindGameObjectWithTag("Player").GetComponent<person>().equiplist;
        color = Color.white;
    }
	
	// Update is called once per frame
	void Update () {

	}

    //show/hide the intro window
    public void OnTooltip(bool show)
    {
        if(show)
        {
            item getitem = database.finditem(gameObject.name);
            Show_Tooltip(getitem);
            GameObject equip = NGUITools.AddChild(gameObject, Tooltip);
            int height = Tooltip.GetComponent<UILabel>().height;
            int width = Tooltip.GetComponent<UILabel>().width;
            Vector3 move = new Vector3(0, height / 2, 0);
            equip.name = "tip";
            equip.transform.localPosition = Vector3.zero - move;
        }
        else
        {
            if (gameObject.transform.childCount > 1)
            {
                Destroy(GameObject.FindGameObjectWithTag("equipmenttip"));
            }
        }
    }

    //show/hide the hint message
    public void Show_Tooltip(item Item)
    {
        Tooltip.GetComponentInChildren<UILabel>().text = "[FF0000]名称:[-] " + Item.itemNameCN + "\n\n" + "[FF0000]说明:[-] " + Item.itemDesc;
    }

    public void OnClick()
    {
        item aitem = new item();
        if(gameObject.transform.parent.name.Contains("equipment"))
        {
            aitem=itemlist[int.Parse(gameObject.transform.parent.name.Replace("equipment",""))];
        }
        if (gameObject.transform.parent.name.Contains("equips"))
        {
            aitem = equiplist[int.Parse(gameObject.transform.parent.name.Replace("equips", ""))];
        }
        if (gameObject.transform.parent.name.Contains("potion"))
        {
            aitem = itemlist1[int.Parse(gameObject.transform.parent.name.Replace("potion", ""))];
        }
        if (gameObject.transform.parent.name.Contains("material"))
        {
            aitem = itemlist2[int.Parse(gameObject.transform.parent.name.Replace("material", ""))];
        }
        if (gameObject.transform.parent.name.Contains("upequip"))
        {
            aitem = up.getupitem();
        }
        if (UICamera.currentTouchID == -1 && aitem.isEquip())
        {
            //introduce.transform.localPosition = Vector3.zero;
            introduce.transform.FindChild("icon").GetComponent<UISprite>().spriteName = aitem.itemName;
            introduce.transform.FindChild("name").GetComponent<UILabel>().text = aitem.itemNameCN;
            introduce.transform.FindChild("synopsis").GetComponent<UILabel>().text = aitem.itemDesc;
            introduce.transform.FindChild("StoryPanel").FindChild("story").GetComponent<UILabel>().text = aitem.itemHistory;
            introduce.transform.FindChild("owners").GetComponent<UILabel>().text = aitem.itemOwner;

            if(GameObject.FindGameObjectWithTag("Introduce") !=null)
            {
                GameObject.Destroy(GameObject.FindGameObjectWithTag("Introduce"));
            }

            GameObject.Instantiate(introduce, Vector3.zero, Quaternion.identity);
        }
        if (UICamera.currentTouchID == -2)
        {
            if (aitem.isEquip() && gameObject.transform.parent.name.Contains("equipment"))
            {
                item0 = GameObject.Find("items0").GetComponent<items0>();
                item0.UseItem(int.Parse(gameObject.transform.parent.name.Replace("equipment", "")));
            }
            if (aitem.isPotion() && gameObject.transform.parent.name.Contains("potion"))
            {
                item1 = GameObject.Find("items1").GetComponent<items1>();
                item1.UseItem(int.Parse(gameObject.transform.parent.name.Replace("potion", "")), 1);
            }
            if (aitem.isEquip() && gameObject.transform.parent.name.Contains("equips"))
            {
                bag.unequipup(int.Parse(gameObject.transform.parent.name.Replace("equips", "")), gameObject);
            }
        } 
    }



    protected override void OnDragDropStart()
    {
        base.OnDragDropStart();
        depth1 = gameObject.GetComponent<UISprite>().depth;
        depth2 = gameObject.GetComponentInChildren<UILabel>().depth;
        gameObject.GetComponent<UISprite>().depth = 20;
        gameObject.GetComponentInChildren<UILabel>().depth = 21;
    }

    //logic of drag & drop(release)
    protected override void OnDragDropRelease(GameObject surface)
    {
        base.OnDragDropRelease(surface);
        
        if(gameObject.transform.parent.name.Contains("equipment"))
        {
            int b = int.Parse(gameObject.transform.parent.name.Replace("equipment", ""));
            
            if (surface.tag.Equals("item"))
            {
                int a = int.Parse(surface.name.Replace("equipment", ""));
                gameObject.transform.parent = surface.transform;
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = 2;
                gameObject.GetComponentInChildren<UILabel>().depth = 3;
                if (a != b)
                {
                    itemlist[a] = itemlist[b].Clone();
                    itemlist[b] = new item();
                }    
            }
            else if (surface.tag.Equals("up"))
            {
                gameObject.transform.parent = surface.transform;
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = 10;
                gameObject.GetComponentInChildren<UILabel>().depth = 11;

                string name = "";
                equipup.transform.FindChild("upname").GetComponent<UILabel>().text = itemlist[b].itemNameCN;
                if (itemlist[b].itemUp.Count > 0)
                {
                    int x = 0;
                    for (int i = 0; i < itemlist[b].itemUp[0].UpNeed.Count; i++)
                    {
                        name = database.finditem(itemlist[b].itemUp[0].UpNeed[i]).itemNameCN;
                        equipup.transform.FindChild("need" + i).GetComponent<UILabel>().text =
                            name + "  x" + itemlist[b].itemUp[0].UpNeedNumber[i];
                        x = i + 1;
                    }
                    for (; x < 4; x++)
                    {
                        equipup.transform.FindChild("need" + x).GetComponent<UILabel>().text = "";
                    }

                    bool has = true;
                    bool has2 = false;
                    for (int i = 0; i < itemlist[b].itemUp[0].UpNeed.Count; i++)
                    {
                        if (i == 0)
                            has2 = true;
                        has = bag.hasitem(itemlist[b].itemUp[0].UpNeed[i], itemlist[b].itemUp[0].UpNeedNumber[i]);
                        if (has)
                        {
                            equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = Color.green;
                        }
                        else
                        {
                            equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = color;
                        }
                        has2 = has2 && has;
                    }
                    if (has2)
                    {
                        equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = true;
                    }
                    else
                        equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;
                }
                else
                {
                    for (int i = 0; i < 4; i++)
                    {
                        equipup.transform.FindChild("need" + i).GetComponent<UILabel>().text = "";
                        equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = color;
                    }
                    equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;
                }
                up.setupitem(itemlist[b]);
                itemlist[b] = new item();
            }
            else if (surface.tag.Equals("equipment"))
            {
                if (surface.transform.parent.name.Contains("equipment"))
                {
                    Transform parent = surface.transform.parent;
                    int a = int.Parse(surface.transform.parent.name.Replace("equipment", ""));

                    surface.transform.parent = gameObject.transform.parent;
                    surface.transform.localPosition = Vector3.zero;
                    gameObject.transform.parent = parent;
                    gameObject.transform.localPosition = Vector3.zero;
                    gameObject.GetComponent<UISprite>().depth = 2;
                    gameObject.GetComponentInChildren<UILabel>().depth = 3;
                    
                    item temp = itemlist[a].Clone();
                    itemlist[a] = itemlist[b].Clone();
                    itemlist[b] = temp;
                }
                if (surface.transform.parent.name.Contains("equips") && itemlist[b].isEquip())
                {
                    int a = int.Parse(surface.transform.parent.name.Replace("equips", ""));
                    string equip = itemlist[b].itemType.ToString();
                    int c = int.Parse(equip.Substring(equip.Length - 1, 1));
                    if (a == c)
                    {
                        Transform parent = surface.transform.parent;
                        surface.transform.parent = gameObject.transform.parent;
                        surface.transform.localPosition = Vector3.zero;
                        gameObject.transform.parent = parent;
                        gameObject.transform.localPosition = Vector3.zero;
                        gameObject.GetComponent<UISprite>().depth = 6;
                        gameObject.GetComponentInChildren<UILabel>().depth = 7;
                        surface.GetComponent<UISprite>().depth = 2;
                        surface.GetComponentInChildren<UILabel>().depth = 3;

                        equiplist[a].unEquip();
                        itemlist[b].equip();
                        item temp = equiplist[a].Clone();
                        equiplist[a] = itemlist[b].Clone();
                        itemlist[b] = temp;
                    }
                    else
                    {
                        gameObject.transform.localPosition = Vector3.zero;
                        gameObject.GetComponent<UISprite>().depth = depth1;
                        gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                    }
                }
                //drop on the upgrade box
                if (surface.transform.parent.name.Contains("upequip") && itemlist[b].isEquip())
                {
                    Transform parent = surface.transform.parent;
                    surface.transform.parent = gameObject.transform.parent;
                    surface.transform.localPosition = Vector3.zero;
                    gameObject.transform.parent = parent;
                    gameObject.transform.localPosition = Vector3.zero;
                    gameObject.GetComponent<UISprite>().depth = 10;
                    gameObject.GetComponentInChildren<UILabel>().depth = 11;
                    surface.GetComponent<UISprite>().depth = 2;
                    surface.GetComponentInChildren<UILabel>().depth = 3;

                    string name = "";
                    equipup.transform.FindChild("upname").GetComponent<UILabel>().text = itemlist[b].itemNameCN;
                    if (itemlist[b].itemUp.Count > 0)
                    {
                        //equipup.transform.FindChild("upname1").GetComponent<UILabel>().text = database.finditem(itemlist[b].itemUp[0].upName).itemNameCN;
                        int x = 0;
                        for (int i = 0; i < itemlist[b].itemUp[0].UpNeed.Count; i++)
                        {
                            name = database.finditem(itemlist[b].itemUp[0].UpNeed[i]).itemNameCN;
                            equipup.transform.FindChild("need" + i).GetComponent<UILabel>().text =
                                name + "  x" + itemlist[b].itemUp[0].UpNeedNumber[i];
                            x = i + 1;
                        }
                        for ( ; x < 4; x++)
                        {
                            equipup.transform.FindChild("need" + x).GetComponent<UILabel>().text ="";
                        }

                        bool has = true;
                        bool has2=false;
                        for (int i = 0; i < itemlist[b].itemUp[0].UpNeed.Count; i++)
                        {
                            if (i == 0)
                                has2 = true;
                            has = bag.hasitem(itemlist[b].itemUp[0].UpNeed[i], itemlist[b].itemUp[0].UpNeedNumber[i]);
                            if (has)
                            {
                                equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = Color.green;
                            }
                            else
                            {
                                equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = color;
                            }
                            has2 = has2 && has;
                        }
                        if (has2)
                        {
                            equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = true;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < 4; i++)
                        {
                            equipup.transform.FindChild("need" + i).GetComponent<UILabel>().text = "";
                            equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = color;
                        }
                        equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;
                    }

                    item temp = up.getupitem().Clone();
                    up.setupitem(itemlist[b]);
                    itemlist[b] = temp;
                }
            }
            else if (surface.tag.Equals("equip") && itemlist[b].isEquip())
            {
                int a = int.Parse(surface.name.Replace("equips", ""));
                string equip = itemlist[b].itemType.ToString();
                int c = int.Parse(equip.Substring(equip.Length - 1, 1));
                if (a == c)
                {
                    gameObject.transform.parent = surface.transform;
                    gameObject.transform.localPosition = Vector3.zero;
                    gameObject.GetComponent<UISprite>().depth = 6;
                    gameObject.GetComponentInChildren<UILabel>().depth = 7;

                    itemlist[b].equip();
                    equiplist[a] = itemlist[b].Clone();
                    itemlist[b] = new item();
                }
                else
                {
                    gameObject.transform.localPosition = Vector3.zero;
                    gameObject.GetComponent<UISprite>().depth = depth1;
                    gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                } 
            }
            else
            {
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = depth1;
                gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                isdelete.transform.localPosition = UpPosition.transform.localPosition;
                isdelete.transform.FindChild("label").GetComponent<UILabel>().text = "确定删除 \"" + "[FF0000]"+itemlist[b].itemNameCN+"[-]" + "\" 吗？";
                isdelete.GetComponent<delete>().setdelete(gameObject, 0, b);
            }
        }
        else if (gameObject.transform.parent.name.Contains("equips") && GameObject.Find("items0"))
        {
            int b = int.Parse(gameObject.transform.parent.name.Replace("equips", ""));
            if (surface.tag.Equals("item"))
            {
                int a = int.Parse(surface.name.Replace("equipment", ""));
                gameObject.transform.parent = surface.transform;
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = 2;
                gameObject.GetComponentInChildren<UILabel>().depth = 3;

                equiplist[b].unEquip();
                itemlist[a] = equiplist[b].Clone();
                equiplist[b] = new item();
            }
            else if (surface.tag.Equals("equipment") && surface.transform.parent.name.Contains("equipment"))
            {
                int a = int.Parse(surface.transform.parent.name.Replace("equipment", ""));
                if (itemlist[a].isEquip())
                {
                    string equip = itemlist[a].itemType.ToString();
                    int c = int.Parse(equip.Substring(equip.Length - 1, 1));
                    if (b == c)
                    {
                        Transform parent = surface.transform.parent;
                        surface.transform.parent = gameObject.transform.parent;
                        surface.transform.localPosition = Vector3.zero;
                        gameObject.transform.parent = parent;
                        gameObject.transform.localPosition = Vector3.zero;
                        gameObject.GetComponent<UISprite>().depth = 2;
                        gameObject.GetComponentInChildren<UILabel>().depth = 3;
                        surface.GetComponent<UISprite>().depth = 6;
                        surface.GetComponentInChildren<UILabel>().depth = 7;

                        equiplist[b].unEquip();
                        itemlist[a].equip();
                        item temp = equiplist[b].Clone();
                        equiplist[b] = itemlist[a].Clone();
                        itemlist[a] = temp;
                    }
                    else
                    {
                        gameObject.transform.localPosition = Vector3.zero;
                        gameObject.GetComponent<UISprite>().depth = depth1;
                        gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                    }
                }
            }
            else 
            {
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = depth1;
                gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                if (surface.tag.Equals("Untagged"))
                {
                    isdelete.transform.localPosition = UpPosition.transform.localPosition;
                    isdelete.transform.FindChild("label").GetComponent<UILabel>().text = "确定删除 \"" + "[FF0000]" + equiplist[b].itemNameCN + "[-]" + "\" 吗？";
                    isdelete.GetComponent<delete>().setdelete(gameObject, 1, b);
                }
            }
        }
        else if (gameObject.transform.parent.name.Contains("potion"))
        {
            int b = int.Parse(gameObject.transform.parent.name.Replace("potion", ""));
            if (surface.tag.Equals("item"))
            {
                int a = int.Parse(surface.name.Replace("potion", ""));
                gameObject.transform.parent = surface.transform;
                gameObject.transform.localPosition = Vector3.zero;
                if (a != b)
                {
                    itemlist1[a] = itemlist1[b].Clone();
                    itemlist1[b] = new item();
                } 
            }
            else if (surface.tag.Equals("equipment"))
            {
                if (surface.transform.parent.name.Contains("potion"))
                {
                    Transform parent = surface.transform.parent;
                    int a = int.Parse(surface.transform.parent.name.Replace("potion", ""));

                    surface.transform.parent = gameObject.transform.parent;
                    surface.transform.localPosition = Vector3.zero;
                    gameObject.transform.parent = parent;
                    gameObject.transform.localPosition = Vector3.zero;

                    item temp = itemlist1[a].Clone();
                    itemlist1[a] = itemlist1[b].Clone();
                    itemlist1[b] = temp;
                }
                else
                {
                    gameObject.transform.localPosition = Vector3.zero;
                    gameObject.GetComponent<UISprite>().depth = depth1;
                    gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                }
            }
            else
            {
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = depth1;
                gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                if (surface.tag.Equals("Untagged"))
                {
                    isdelete.transform.localPosition = UpPosition.transform.localPosition;
                    isdelete.transform.FindChild("label").GetComponent<UILabel>().text = "确定删除 \"" + "[FF0000]" + itemlist1[b].itemNameCN + "[-]" + "\" 吗？";
                    isdelete.GetComponent<delete>().setdelete(gameObject, 2, b);
                } 
            }
        }
        else if (gameObject.transform.parent.name.Contains("material"))
        {
            int b = int.Parse(gameObject.transform.parent.name.Replace("material", ""));
            //tempty item box
            if (surface.tag.Equals("item"))
            {
                int a = int.Parse(surface.name.Replace("material", ""));
                gameObject.transform.parent = surface.transform;
                gameObject.transform.localPosition = Vector3.zero;
                if (a != b)
                {
                    itemlist2[a] = itemlist2[b].Clone();
                    itemlist2[b] = new item();
                } 
            }
            else if (surface.tag.Equals("equipment"))
            {
                if (surface.transform.parent.name.Contains("material"))
                {
                    Transform parent = surface.transform.parent;
                    int a = int.Parse(surface.transform.parent.name.Replace("material", ""));

                    surface.transform.parent = gameObject.transform.parent;
                    surface.transform.localPosition = Vector3.zero;
                    gameObject.transform.parent = parent;
                    gameObject.transform.localPosition = Vector3.zero;

                    item temp = itemlist2[a].Clone();
                    itemlist2[a] = itemlist2[b].Clone();
                    itemlist2[b] = temp;
                }
                else
                {
                    gameObject.transform.localPosition = Vector3.zero;
                    gameObject.GetComponent<UISprite>().depth = depth1;
                    gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                }
            }
            else
            {
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = depth1;
                gameObject.GetComponentInChildren<UILabel>().depth = depth2;
                if (surface.tag.Equals("Untagged"))
                {
                    isdelete.transform.localPosition = UpPosition.transform.localPosition;
                    isdelete.transform.FindChild("label").GetComponent<UILabel>().text = "确定删除 \"" + "[FF0000]" + itemlist2[b].itemNameCN + "[-]" + "\" 吗？";
                    isdelete.GetComponent<delete>().setdelete(gameObject, 3, b);
                }
            }
        }
        else if (gameObject.transform.parent.name.Contains("upequip") && GameObject.Find("items0"))
        {
            if (surface.tag.Equals("item"))
            {
                int a = int.Parse(surface.name.Replace("equipment", ""));
                gameObject.transform.parent = surface.transform;
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = 2;
                gameObject.GetComponentInChildren<UILabel>().depth = 3;

                equipup.transform.FindChild("upname").GetComponent<UILabel>().text = "";
                for (int i = 0; i < 4; i++)
                {
                    equipup.transform.FindChild("need" + i).GetComponent<UILabel>().text = "";
                }
                equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;
                itemlist[a] = up.getupitem().Clone();
                up.setupitem(new item());
            }
            else if (surface.tag.Equals("equipment") && surface.transform.parent.name.Contains("equipment"))
            {
                int a = int.Parse(surface.transform.parent.name.Replace("equipment", ""));
                if (itemlist[a].isEquip())
                {
                    Transform parent = surface.transform.parent;
                    surface.transform.parent = gameObject.transform.parent;
                    surface.transform.localPosition = Vector3.zero;
                    gameObject.transform.parent = parent;
                    gameObject.transform.localPosition = Vector3.zero;
                    gameObject.GetComponent<UISprite>().depth = 2;
                    gameObject.GetComponentInChildren<UILabel>().depth = 3;
                    surface.GetComponent<UISprite>().depth = 10;
                    surface.GetComponentInChildren<UILabel>().depth = 11;

                    string name = "";
                    equipup.transform.FindChild("upname").GetComponent<UILabel>().text = itemlist[a].itemNameCN;
                    if (itemlist[a].itemUp.Count > 0)
                    {
                        //equipup.transform.FindChild("upname1").GetComponent<UILabel>().text = database.finditem(itemlist[b].itemUp[0].upName).itemNameCN;
                        int x = 0;
                        for (int i = 0; i < itemlist[a].itemUp[0].UpNeed.Count; i++)
                        {
                            name = database.finditem(itemlist[a].itemUp[0].UpNeed[i]).itemNameCN;
                            equipup.transform.FindChild("need" + i).GetComponent<UILabel>().text =
                                name + "  x" + itemlist[a].itemUp[0].UpNeedNumber[i];
                            x = i + 1;
                        }
                        for (; x < 4; x++)
                        {
                            equipup.transform.FindChild("need" + x).GetComponent<UILabel>().text = "";
                        }

                        bool has = true;
                        bool has2 = false;
                        for (int i = 0; i < itemlist[a].itemUp[0].UpNeed.Count; i++)
                        {
                            if (i == 0)
                                has2 = true;
                            has = bag.hasitem(itemlist[a].itemUp[0].UpNeed[i], itemlist[a].itemUp[0].UpNeedNumber[i]);
                            if (has)
                            {
                                equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = Color.green;
                            }
                            else
                            {
                                equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = color;
                            }
                            has2 = has2 && has;          
                        }
                        if (has2)
                        {
                            equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = true;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < 4; i++)
                        {
                            equipup.transform.FindChild("need" + i).GetComponent<UILabel>().text = "";
                            equipup.transform.FindChild("need" + i).GetComponent<UILabel>().color = color;
                        }
                        equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;
                    }

                    item temp = up.getupitem().Clone();
                    up.setupitem(itemlist[a]);
                    itemlist[a] = temp;
                }
            }
            else if (surface.tag.Equals("delete"))
            {
                Destroy(gameObject);
                up.setupitem(new item());
                equipup.transform.FindChild("upname").GetComponent<UILabel>().text = "";
                for (int i = 0; i < 4; i++)
                {
                    equipup.transform.FindChild("need" + i).GetComponent<UILabel>().text = "";
                }
                equipup.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;
            }
            else
            {
                gameObject.transform.localPosition = Vector3.zero;
                gameObject.GetComponent<UISprite>().depth = depth1;
                gameObject.GetComponentInChildren<UILabel>().depth = depth2;
            }
        }
        else
        {
            gameObject.transform.localPosition = Vector3.zero;
            gameObject.GetComponent<UISprite>().depth = depth1;
            gameObject.GetComponentInChildren<UILabel>().depth = depth2;
        }
    }
}
