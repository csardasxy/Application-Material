using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// This script controls the inventory's add/delete logic.
/// </summary>

public class Delete : MonoBehaviour {

    public GameObject Noposition;
    public List<item> itemlist;//背包数据
    public List<item> itemlist1;//背包数据1
    public List<item> itemlist2;//背包数据2
    public List<item> equiplist;//装备数据
    public GameObject deleteobject;
    public GameObject person;
    public Bag bag;
    private GameObject gameobject;
    private int a, b;
	// Use this for initialization
	void Start () {
        itemlist = bag.equiplist;
        itemlist1 = bag.potionlist;
        itemlist2 = bag.materiallist;
        equiplist = GameObject.FindGameObjectWithTag("Player").GetComponent<person>().equiplist;
	}
	
	// Update is called once per frame
	void Update () {
	
	}

    public void setdelete(GameObject gameobject, int a, int b)
    {
        this.gameobject = gameobject;
        this.a = a;
        this.b = b;
    }

    public void dodelete()
    {
        Destroy(gameobject);
        GameObject deleted = Instantiate(deleteobject);
        if (a == 0)
        {
            deleted.transform.name = itemlist[b].itemName + "_" + itemlist[b].itemNum;
            itemlist[b] = new item();
        }
        if (a == 1)
        {
            deleted.transform.name = equiplist[b].itemName + "_" + equiplist[b].itemNum;
            equiplist[b].unEquip();
            equiplist[b] = new item();
        }
        if(a == 2)
        {
            deleted.transform.name = itemlist1[b].itemName + "_" + itemlist1[b].itemNum;
            itemlist1[b] = new item();
        }
        if (a == 3)
        {
            deleted.transform.name = itemlist2[b].itemNameCN + "_" + itemlist2[b].itemNum;
            itemlist2[b] = new item();
        }
        deleted.transform.position = person.transform.position;
        gameObject.transform.localPosition = Noposition.transform.localPosition;
    }
    public void notdelete()
    {
        gameObject.transform.localPosition = Noposition.transform.localPosition;
    }
}
