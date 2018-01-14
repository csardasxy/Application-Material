using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// This script contains the character's attributes and functions related
/// </summary>

public class person : MonoBehaviour {

    public string name;
    public int HP, MP, HPNOW, MPNOW;
    public int ATK, DEF;
    public int DEX, CRI, EVA, BLK;//命中 暴击 闪避 格挡
    
    public List<item> equiplist = new List<item>();
    public int number = 4;
	// Use this for initialization
	void Start () {
        for (int i = 0; i < number; i++)
        {
            equiplist.Add(new item());
        }
        HP = 100;
        MP = 100;
        HPNOW = 100;
        MPNOW = 100;
        ATK = 100;
        DEF = 100;
        DEX = 100;
        CRI = 100;
        EVA = 100;
        BLK = 100;
	}
	
	// Update is called once per frame
	void Update () {
	
	}



    //装备物品相关
    public void setHP(float a)
    {
        HP += (int)a;
    }
    public void setMP(float a)
    {
        MP += (int)a;
    }
    public void setHPNOW(float a)
    {
        if (a < HP - HPNOW)
        {
            HPNOW += (int)a;
        }
        else
            HPNOW = HP;
    }
    public void setMPNOW(float a)
    {
        if (a < MP - MPNOW)
            MPNOW += (int)a;
        else
            MPNOW = MP;
    }
    public void setATK(float a)
    {
        ATK += (int)a;
    }
    public void setDEF(float a)
    {
        DEF += (int)a;
    }
    public void setDEX(float a)
    {
        DEX += (int)a;
    }
    public void setCRI(float a)
    {
        CRI += (int)a;
    }
    public void setEVA(float a)
    {
        EVA += (int)a;
    }
    public void setBLK(float a)
    {
        BLK += (int)a;
    }
    
    public void downHP(float a)
    {
        HP -= (int)a;
        if (HPNOW > HP)
            HPNOW = HP;
    }
    public void downMP(float a)
    {
        MP -= (int)a;
        if (HPNOW > HP)
            HPNOW = HP;
    }
    public void downHPNOW(float a)
    {
        HPNOW -= (int)a;
    }

    //this return value can be judged to enable or disable character's magic & skill
    public bool downMPNOW(float a)
    {
        if (MPNOW - a > 0)
        {
            MPNOW -= (int)a;
            return true;
        }
        else
            return false;
    }
    public void downATK(float a)
    {
        ATK -= (int)a;
    }
    public void downDEF(float a)
    {
        DEF -= (int)a;
    }
    public void downDEX(float a)
    {
        DEX -= (int)a;
    }
    public void downCRI(float a)
    {
        CRI -= (int)a;
    }
    public void downEVA(float a)
    {
        EVA -= (int)a;
    }
    public void downBLK(float a)
    {
        BLK -= (int)a;
    }

}
