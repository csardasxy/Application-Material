using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// functions for euipments' configuration
/// </summary>

public class items1 : MonoBehaviour {
    
    public class Change{
        public int changeType;
        public int id;
        public int index;

        public Change(int type, int aid, int aindex)
        {
            this.changeType = type;
            this.id = aid;
            this.index = aindex;
        }
    }

    public GameObject item0;
    public GameObject item2;
    public GameObject itemb;
    public GameObject equipment;
    public Bag bag;
    public int bagcount = 20;

    public List<item> itemlist;//item in inventory's linear list
    public person per;
    public List<item> equiplist = new List<item>();
    public itemdb datebase;

    private bool isfirst = true;
    private bool hasChanged = false;
    private Change achange;

    Queue<Change> change;

	void Start () {
        change = new Queue<Change>();
        itemlist = bag.potionlist;
    }
	
    void Update()
    {
        if (isfirst)
            first();
        if (hasChanged)
        {
            while(change.Count > 0)
            {
                achange = change.Dequeue();
                GameObject aitem = GameObject.Find("potion" + achange.index);
                if (achange.changeType == 0)
                {
                    aitem.GetComponentInChildren<UILabel>().text
                            = itemlist[achange.index].itemNum + "";
                }
                if (achange.changeType == 1)
                {
                    GameObject equip = NGUITools.AddChild(aitem, equipment);
                    equip.transform.localScale = new Vector3(1, 1, 1);
                    equip.transform.localPosition = Vector3.zero;
                    equip.name = datebase.finditem(achange.id).itemName;
                    equip.GetComponent<UISprite>().spriteName = datebase.finditem(achange.id).itemName;
                    equip.GetComponentInChildren<UILabel>().text = "";
                }
                if (achange.changeType == 2)
                {
                    aitem.transform.DestroyChildren();
                }
            }
            hasChanged = false;
        }
    }

    public void first()
    {
        for (int i = 0; i < bagcount; i++)
        {
            GameObject newitem = NGUITools.AddChild(gameObject, itemb);
            newitem.name = "potion" + i;
            itemlist.Add(new item());
        }
        gameObject.GetComponent<UIGrid>().Reposition();
        isfirst = false;
    }

    public void AddItem(int id,int num)
    {
        if (!is_Full(id, num))
        {
            for (int a = 0; a < num; a++)
            {
                int i;
                int listnumber = itemlistContains(id);
                //judge if this item can be overlayed
                if (listnextindex(id) != -1)
                {
                    int index = listnextindex(id);
                    itemlist[index].itemNum++;
                    change.Enqueue(new Change(0, id, index));
                }
                //if it cannot be overlayed, then add it into a new box
                else
                {
                    i = listemptyindex();
                    itemlist[i] = datebase.finditem(id).Clone();
                    //UI related
                    change.Enqueue(new Change(1, id, i));
                }
            }
            hasChanged = true;
        }  
    }

    //judge whether the inventory is full
    public bool is_Full(int id, int num)
    {
        if (listemptyindex() != -1)
        {
            return false;
        }
        else
        {
           int listnumber = itemlistContains(id);
           int leftcount = 0;
           if (listnumber == -1)
               return true;
           else
           {
               for (; listnumber < itemlist.Count; listnumber++)
               {
                   print(listnumber);
                   if (itemlist[listnumber].itemID == id)
                   {
                       int itemleftnumber = itemlist[listnumber].itemMaxNum - itemlist[listnumber].itemNum;
                       leftcount += itemleftnumber;
                       print(leftcount);
                       if (leftcount > num)
                           return false;
                   }  
               }
               return true;
            }
        }
    }

    //judge whther this item is in the inventory's list
    public int itemlistContains(int id)
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            if (itemlist[i].itemID == id)
            {
                return i;
            }
        }
        return -1;
    }

    //get the first empty box' position in inventory
    public int listemptyindex()
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            if (itemlist[i].itemID == -1)
            {
                return i;
            }
        }
        return -1;
    }
    
    public int listnextindex(int id)
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            if (itemlist[i].itemID == id &&
                  itemlist[i].itemNum < itemlist[i].itemMaxNum)
                return i;
        }
        return -1;
    }

    
    public void UseItem(int id, int num)
    {
        itemlist[id].equip();
        itemlist[id].itemNum -= num;
        //数量为消耗时清空物品格
        if (itemlist[id].itemNum == num)
        {
            itemlist[id] = new item();
            change.Enqueue(new Change(2, num, id));
        }
        else
        {
            change.Enqueue(new Change(0, num, id));
        }
        hasChanged = true;
    }

    //use this item for upgrading euipments
    public void UseUpItem(int id, int num)
    {
        itemlist[id].itemNum -= num;
        if (itemlist[id].itemNum == num)
        {
            itemlist[id] = new item();
            change.Enqueue(new Change(2, num, id));
        }
        else
        {
            change.Enqueue(new Change(0, num, id));
        }
        hasChanged = true;
    }

    public void RemoveItem(int id)
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            if (itemlist[i].itemID == id)
            {
                GameObject.Find("potion" + i).transform.DestroyChildren();
                itemlist[i] = new item();
                break;
            }
        }
    }
    
    public void Saveitemlist()
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            PlayerPrefs.SetInt("itemlist" + i, itemlist[i].itemID);
            PlayerPrefs.SetInt("itemlistNum" + i, itemlist[i].itemNum);
        }
    }

    public void Loaditemlist()
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            itemlist[i] = PlayerPrefs.GetInt("itemlist" + i, -1) >= 0 ? datebase.items[PlayerPrefs.GetInt("itemlist" + i)] : new item();

            itemlist[i].itemNum = PlayerPrefs.GetInt("itemlistNum" + i, 1);
        }
    }

    

    //get the amount of available space of imventory
    public int GetSoltNum()
    {
        int count = 0;
        for (int i = 0; i < itemlist.Count; i++)
        {
            if (itemlist[i].itemID == -1)
            {
                count++;
            }
        }
        return count;
    }

    public void showPotion()
    {
        item0.SetActive(false);
        item2.SetActive(false);
        if (!gameObject.activeSelf)
        {
            gameObject.SetActive(true);
        }
    }
}
