using UnityEngine;
using System.Collections;
using System.Collections.Generic;
public class Bag : MonoBehaviour {

    public GameObject noposition;
    public GameObject showposition;
    public GameObject introduce;
    public items0 item0;
    public person per;
    bool show = false;
    Vector3 position;
    Vector3 sposition;

    public TP_Animator ta;

    public List<item> equiplist = new List<item>();
    public List<item> potionlist = new List<item>();
    public List<item> materiallist = new List<item>();
	// Use this for initialization
	void Start () {
        ta = GameObject.FindGameObjectWithTag("Player").GetComponent<TP_Animator>();
    }

    // Update is called once per frame
    void Update () {
        sposition = showposition.transform.localPosition;
        position = noposition.transform.localPosition;
	}

    public bool hasitem(string name, int number)
    {
        int num = 0;
        for (int i = 0; i < materiallist.Count; i++)
        {
            if (materiallist[i].itemID != -1)
            {
                if (materiallist[i].itemName.Equals(name))
                {
                    num += materiallist[i].itemNum;
                }
            }
            if (num >= number)
            {
                return true;
            }
        }
        for (int i = 0; i < equiplist.Count; i++)
        {
            if (equiplist[i].itemID != -1)
            {
                if (equiplist[i].itemName.Equals(name))
                {
                    num += equiplist[i].itemNum;
                }
            }
            if (num > number)
                return true;
        }
        for (int i = 0; i < potionlist.Count; i++)
        {
            if (potionlist[i].itemID != -1)
            {
                if (potionlist[i].itemName.Equals(name))
                {
                    num += potionlist[i].itemNum;
                }
            }
            if (num > number)
                return true;
        }
        return false;
    }

    public int itemid(string name)
    {
        for (int i = 0; i < materiallist.Count; i++)
        {
            if (materiallist[i].itemID != -1)
            {
                if (materiallist[i].itemName.Equals(name))
                    return i;
            }
        }
        for (int i = 0; i < equiplist.Count; i++)
        {
            if (equiplist[i].itemID != -1)
            {
                if (equiplist[i].itemName.Equals(name))
                    return i;
            }
        }
        for (int i = 0; i < potionlist.Count; i++)
        {
            if (potionlist[i].itemID != -1)
            {
                if (potionlist[i].itemName.Equals(name))
                    return i;
            }
        }
        return -1;
    }

    public void unequipup(int id, GameObject gameobject)
    {
        int empty = item0.listemptyindex();
        if (empty != -1)
        {
            gameobject.GetComponent<UISprite>().depth = -5;
            gameobject.GetComponent<UISprite>().width -= 10;
            gameobject.GetComponent<UISprite>().height -= 10;
            gameobject.GetComponentInChildren<UILabel>().depth = -4;

            per.equiplist[id].unEquip();
            item0.itemlist[empty] = per.equiplist[id].Clone();
            per.equiplist[id] = new item();
            item0.MoveItem(empty, id);
        }
    }

    public void showbag()
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

    public void moveIntroduce()
    {
        Debug.Log("close");
        introduce = GameObject.FindGameObjectWithTag("Introduce");
        GameObject.Destroy(introduce);
        introduce.transform.localPosition = position;
    }

}
