using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class items0 : MonoBehaviour {
    //物品变更内部类
    public class Change{
        public int changeType;//改变类型
        public int id;//改变物体id
        public int index;//改变物体位置

        public Change(int type, int aid, int aindex)
        {
            this.changeType = type;
            this.id = aid;
            this.index = aindex;
        }
    }

    public GameObject itemb;
    public GameObject equipment;
    public GameObject item1;
    public GameObject item2;
    public GameObject equip;
    public GameObject aitem;

    public Bag bag;
    public int bagcount = 20;

    public List<item> itemlist;//定义背包物品线性表
    public person per;
    public List<item> equiplist;
    public itemdb datebase;//物品数据


    private bool hasChanged = false;
    private Change achange;

    Queue<Change> change;

	void Start () {
        change = new Queue<Change>();
        gameObject.GetComponent<UIGrid>().Reposition();
        gameObject.GetComponent<UIGrid>().enabled = true;
        itemlist = bag.equiplist;
        equiplist = per.equiplist;
        first();
	}
	
    void Update()
    {
        if (hasChanged)
        {
            while(change.Count > 0)
            {
                achange = change.Dequeue();
                if (achange.changeType != 5)
                    aitem = GameObject.Find("equipment" + achange.index);
                if (achange.changeType == 5)
                    aitem = GameObject.Find("equips" + achange.index);
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
                    Transform useitem = aitem.transform.GetChild(0);
                    useitem.parent = equip.transform.FindChild("equips" + achange.id);
                    useitem.localPosition = Vector3.zero;
                    useitem.GetComponent<UISprite>().depth = 6;
                    useitem.GetComponentInChildren<UILabel>().depth = 7;
                }
                if (achange.changeType == 3)
                {
                    Transform useitem = aitem.transform.GetChild(0);
                    Transform child = equip.transform.FindChild("equips" + achange.id).transform.GetChild(0);
                    useitem.transform.parent = equip.transform.FindChild("equips" + achange.id);
                    child.transform.parent = aitem.transform;
                    useitem.localPosition = Vector3.zero;
                    child.localPosition = Vector3.zero;
                    useitem.GetComponent<UISprite>().depth = 6;
                    useitem.GetComponentInChildren<UILabel>().depth = 7;
                    child.GetComponent<UISprite>().depth = 2;
                    child.GetComponentInChildren<UILabel>().depth = 3;
                }
                if (achange.changeType == 4)
                {
                    aitem.transform.DestroyChildren();
                }
                if (achange.changeType == 5)
                {
                    Transform useitem = aitem.transform.GetChild(0);
                    useitem.transform.parent = gameObject.transform.FindChild("equipment" + achange.id);
                    useitem.transform.localPosition = Vector3.zero;
                    useitem.GetComponent<UISprite>().depth = 2;
                    useitem.GetComponent<UISprite>().width += 10;
                    useitem.GetComponent<UISprite>().height += 10;
                    useitem.GetComponentInChildren<UILabel>().depth = 3;
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
            newitem.name = "equipment" + i;
            itemlist.Add(new item());
        }
    }


    //添加物品
    public void AddItem(int id,int num)
    {
        if (!is_Full(id, num))
        {
            for (int a = 0; a < num; a++)
            {
                int i;
                int listnumber = itemlistContains(id);
                //背包中该物品仍可叠加
                if (listnextindex(id) != -1)
                {
                    int index = listnextindex(id);
                    itemlist[index].itemNum++;
                    //UI相关
                    change.Enqueue(new Change(0, id, index));
                }
                //背包中该物品不可叠加，则新建一个物品格
                else
                {
                    i = listemptyindex();
                    itemlist[i] = datebase.finditem(id).Clone();
                    //UI相关
                    change.Enqueue(new Change(1, id, i));
                }
            }
            hasChanged = true;
        }  
    }

    //添加物品
    public void MoveItem(int id, int index)
    {
        change.Enqueue(new Change(5, id, index));
        hasChanged = true;
    }

    //判断背包是否已满
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

    //判断对应ID物品是否在背包里
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

    //获取背包第一个空格位置
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

    //判断物品是否可叠加
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


    //背包物品使用
    public void UseItem(int id)
    {
        //数量为1时清空物品格
        if (itemlist[id].itemNum == 1)
        {
            if(itemlist[id].isEquip())
            {
                int a = itemlist[id].equipNo();
                if (equiplist[a].itemID == -1)
                {
                    itemlist[id].equip();
                    equiplist[a] = itemlist[id].Clone();
                    itemlist[id] = new item();
                    change.Enqueue(new Change(2, a, id));
                }
                else
                {
                    equiplist[a].unEquip();
                    itemlist[id].equip();
                    item temp = equiplist[a].Clone();
                    equiplist[a] = itemlist[id].Clone();
                    itemlist[id] = temp;
                    change.Enqueue(new Change(3, a, id));
                }
            }
            hasChanged = true;
        }
    }

    //背包物品升级使用
    public void UseUpItem(int id, int num)
    {
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


    //删除背包物品
    public void RemoveItem(int id)
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            if (itemlist[i].itemID == id)
            {
                GameObject.Find("equipment" + i).transform.DestroyChildren();
                itemlist[i] = new item();
                break;
            }
        }
    }

    //保存背包物品
    public void Saveitemlist()
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            PlayerPrefs.SetInt("itemlist" + i, itemlist[i].itemID);
            PlayerPrefs.SetInt("itemlistNum" + i, itemlist[i].itemNum);
        }
    }
    //加载背包物品
    public void Loaditemlist()
    {
        for (int i = 0; i < itemlist.Count; i++)
        {
            itemlist[i] = PlayerPrefs.GetInt("itemlist" + i, -1) >= 0 ? datebase.items[PlayerPrefs.GetInt("itemlist" + i)] : new item();

            itemlist[i].itemNum = PlayerPrefs.GetInt("itemlistNum" + i, 1);
        }
    }

    

    //获取背包剩余空格数量
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

    public void showEquip()
    {
        item1.SetActive(false);
        item2.SetActive(false);
        if (!gameObject.activeSelf)
        {
            gameObject.SetActive(true);
        }
    }

    
}
