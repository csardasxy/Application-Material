using UnityEngine;
using System.Collections;

/// <summary>
/// update item information (type & count) in backpack (when hero pick up the dropouts of enemies)
/// </summary>
public class PickUp : MonoBehaviour {

    public GameObject noposition;
    public GameObject showposition;
    bool show = false;
    Vector3 position;
    Vector3 sposition;
    public item upitem;
    public items0 item0;
    public items1 item1;
    public items2 item2;
    public Bag bag;
    public itemdb datebase;
    TP_Animator ta;

	// Use this for initialization
	void Start () {
        ta = GameObject.FindGameObjectWithTag("Player").GetComponent<TP_Animator>();
        upitem = new item();
        gameObject.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;

	}
	
	// Update is called once per frame
	void Update () {
        sposition = showposition.transform.localPosition;
        position = noposition.transform.localPosition;
	}

    public void setupitem(item a)
    {
        upitem = a.Clone();
    }
    public item getupitem()
    {
        return upitem;
    }

    public void showup()
    {
        if (show)
        {
            gameObject.transform.localPosition = position;
            show = false;
            ta.canAttack++;
        }
        else
        {
            gameObject.transform.localPosition = sposition;
            show = true;
            ta.canAttack--;
        }
    }

    public void equipup()
    {   
        for (int i = 0; i < upitem.itemUp[0].UpNeed.Count; i++)
        {
            for (int a = 0; a < upitem.itemUp[0].UpNeedNumber[i]; a++)
            {
                if (datebase.finditem(upitem.itemUp[0].UpNeed[i]).isEquip())
                {
                    item0.UseUpItem(bag.itemid(upitem.itemUp[0].UpNeed[i]), 1);
                }
                else if (datebase.finditem(upitem.itemUp[0].UpNeed[i]).isPotion())
                {
                    item1.UseUpItem(bag.itemid(upitem.itemUp[0].UpNeed[i]), 1);
                }
                else 
                {
                    item2.UseUpItem(bag.itemid(upitem.itemUp[0].UpNeed[i]), 1);
                }
            }  
        }
        //Add a new item
        string owners = upitem.itemOwner;
        upitem = datebase.finditem(upitem.itemUp[0].upName).Clone();
        upitem.addowners(owners);
        //update item's icon
        Transform aequip = gameObject.transform.FindChild("upequip").GetChild(0);
        aequip.name = upitem.itemName;
        aequip.GetComponent<UISprite>().spriteName = upitem.itemName;
        aequip.GetComponentInChildren<UILabel>().text = "";
        //update item's info
        gameObject.transform.FindChild("upname").GetComponent<UILabel>().text = upitem.itemNameCN;
        int x = 0;
        if (upitem.itemUp.Count > 0)
        {
            for (int i = 0; i < upitem.itemUp[0].UpNeed.Count; i++)
            {
                string name = datebase.finditem(upitem.itemUp[0].UpNeed[i]).itemNameCN;
                gameObject.transform.FindChild("need" + i).GetComponent<UILabel>().text =
                    name + "  x" + upitem.itemUp[0].UpNeedNumber[i];
                x = i + 1;
            }
            for (; x < 4; x++)
            {
                gameObject.transform.FindChild("need" + x).GetComponent<UILabel>().text = "";
            }

            bool has = true;
            bool has2 = false; 
            for (int i = 0; i < upitem.itemUp[0].UpNeed.Count; i++)
            {
                if (i == 0)
                    has2 = true;
                has = bag.hasitem(upitem.itemUp[0].UpNeed[i], upitem.itemUp[0].UpNeedNumber[i]);
                if (has)
                {
                    gameObject.transform.FindChild("need" + i).GetComponent<UILabel>().color = Color.green;
                }
                else
                {
                    gameObject.transform.FindChild("need" + i).GetComponent<UILabel>().color = Color.white;
                }
                has2 = has2 && has;
            }
            if (has2)
            {
                gameObject.transform.FindChild("up").GetComponent<UIButton>().isEnabled = true;
            }
            else
                gameObject.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;
        }
        else
        {
            for (int i = 0; i < 4; i++)
            {
                gameObject.transform.FindChild("need" + i).GetComponent<UILabel>().text = "";
            }
            gameObject.transform.FindChild("up").GetComponent<UIButton>().isEnabled = false;
        }
    }
}
