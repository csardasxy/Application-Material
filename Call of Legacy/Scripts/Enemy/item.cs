using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// This contains equipments' history ,description and so on.
/// In this game, the euipments' description chages with the events
///     (such as the death of the former owner, being stolen by enemy, and slaying powerful elite enemies
/// </summary>

[System.Serializable]
public class item
{
    public string itemName;
    public int itemID;
    public string itemNameCN;
    public string itemDesc;
    public string itemHistory;
    public string itemOwner;
    public int itemNum;
    public int itemMaxNum;
    public int itemSetNum;
    public ItemType itemType;
    public List<Up> itemUp = new List<Up>();
    public List<Property> itemProperty = new List<Property>();
    public person aPerson;

    public enum ItemType
    {
        Weapon0,//sword
        Hat1,//helmet
        Shield2,
        Armor3,
        Potion,
        Material,
    }

    //装备升级所需材料内部类
    public class Up
    {
        public string upName;//the name of upgraded item
        public List<string> UpNeed = new List<string>();//materials needed
        public List<int> UpNeedNumber = new List<int>();//amount of materials needed

        public Up(string name, string need, int neednumber)
        {
            this.upName = name;
            this.UpNeed.Add(need);
            this.UpNeedNumber.Add(neednumber);
        }

        public void add(string need, int neednumber)
        {
            this.UpNeed.Add(need);
            this.UpNeedNumber.Add(neednumber);
        }
    }

    //装备升级所需材料内部类
    public class Property
    {
        public int propertyNumber;    
        public int property;//属性数值

        public Property(int number, int a)
        {
            this.propertyNumber = number;
            this.property = a;
        }

    }

    //initialize funcion of equipments
    public item(string name, int id, string nameCN, string desc, int max_num, ItemType type)
    {
        itemName = name;
        itemID = id;
        itemNameCN = nameCN;
        itemDesc = desc;
        itemNum = 1;
        itemMaxNum = max_num;
        itemType = type;
    }


    //empty initialize funcion
    public item()
    {
        itemID = -1;
    }

    //deep copy funcion
    public item Clone()
    {
        return this.MemberwiseClone() as item;
    }

    //upgrade equipments
    public void addUp(string name, string need, int neednumber)
    {
        itemUp.Add(new Up(name, need, neednumber));
    }
    public void addUpExtra(int number, string need, int neednumber)
    {
        itemUp[number].add(need, neednumber);
    }

    //add a property (type, value) to an equipment
    public void addProperty(int number, int a)
    {
        itemProperty.Add(new Property(number, a));
    }

    //add history to an equipment
    public void addHistory(string history)
    {
        itemHistory = history;
    }
    // add an owner's to the euipment
    public void addowners(string name)
    {
        if (!itemOwner.Equals(""))
            itemOwner = itemOwner + "," + name;
        else
            itemOwner = name;
    }
    // add an owner's to the euipment


    //after equiping, the hero's property can be changed
    public void equip()
    {
        Property a;
        aPerson = GameObject.FindGameObjectWithTag("Player").GetComponent<person>();
        for (int i = 0; i < itemProperty.Count; i++)
        {
            a = itemProperty[i];
            switch(a.propertyNumber){
                case 0:
                    aPerson.setHP(a.property);
                    break;
                case 1:
                    aPerson.setHPNOW(a.property);
                    break;
                case 2:
                    aPerson.setMP(a.property);
                    break;
                case 3:
                    aPerson.setMPNOW(a.property);
                    break;
                case 4:
                    aPerson.setATK(a.property);
                    break;
                case 5:
                    aPerson.setDEF(a.property);
                    break;
                case 6:
                    aPerson.setDEX(a.property);
                    break;
                case 7:
                    aPerson.setCRI(a.property);
                    break;
                case 8:
                    aPerson.setEVA(a.property);
                    break;
                case 9:
                    aPerson.setBLK(a.property);
                    break;
                default:
                    break;
            }     
        }
    }

    //change equipment
    public void unEquip()
    {
        Property a;
        aPerson = GameObject.FindGameObjectWithTag("Player").GetComponent<person>();
        for (int i = 0; i < itemProperty.Count; i++)
        {
            a = itemProperty[i];
            switch (a.propertyNumber)
            {
                case 0:
                    aPerson.downHP(a.property);
                    break;
                case 1:
                    aPerson.downHPNOW(a.property);
                    break;
                case 2:
                    aPerson.downMP(a.property);
                    break;
                case 3:
                    aPerson.downMPNOW(a.property);
                    break;
                case 4:
                    aPerson.downATK(a.property);
                    break;
                case 5:
                    aPerson.downDEF(a.property);
                    break;
                case 6:
                    aPerson.downDEX(a.property);
                    break;
                case 7:
                    aPerson.downCRI(a.property);
                    break;
                case 8:
                    aPerson.downEVA(a.property);
                    break;
                case 9:
                    aPerson.downBLK(a.property);
                    break;
                default:
                    break;
            }
        }
    }

    public bool isEquip()
    {
        if (itemType.Equals(ItemType.Weapon0) || itemType.Equals(ItemType.Hat1) || itemType.Equals(ItemType.Shield2) || itemType.Equals(ItemType.Armor3))
        {
            return true;
        }
        return false;
    }

    public bool isPotion()
    {
        if (itemType.Equals(ItemType.Potion))
        {
            return true;
        }
        return false;
    }

    public int equipNo()
    {
        if (itemType.Equals(ItemType.Weapon0))
            return 0;
        if (itemType.Equals(ItemType.Hat1))
            return 1;
        if (itemType.Equals(ItemType.Shield2))
            return 2;
        if (itemType.Equals(ItemType.Armor3))
            return 3;
        return -1;
    }
}

