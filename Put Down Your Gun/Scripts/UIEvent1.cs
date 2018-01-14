using UnityEngine;
using System.Collections;

/// <summary>
/// This script related to the final scene. 
/// It is a simple event triggered by the player's choice.
/// 3 different UI events are attached to different game objects in the scene.
/// </summary>

public class UIEvent1 : MonoBehaviour {
    
    public GameObject[] panels;
    [SerializeField]
    Transform generatePoint;
    [SerializeField]
    GameObject key1, hero, TrueEnemy;
    int addCount = 8;
    bool done = false;
    bool die = false;
    [SerializeField]
    GameObject backText;
    // Use this for initialization
    void Start () {
        panels[0].GetComponent<FadeOff>().StartTimer();
        hero.GetComponent<Aim_Shoot>().canShoot = false;
	}
	
	// Update is called once per frame
	void Update () {
        if(hero.GetComponent<health>().die && !die)
        {
            panels[1].GetComponent<FadeOff>().StartTimer();
            panels[3].SetActive(true);
            die = true;
        }
	    if(key1.GetComponent<health>().die && !done)
        {
            //If the character shoots and kills his commander, all of his ally will turn into his enemy.
            backText.SetActive(true);
            panels[1].GetComponent<FadeOff>().StartTimer();
            panels[2].GetComponent<FadeOff>().StartTimer();
            this.gameObject.GetComponent<AudioSource>().clip = Resources.Load("C21FX MUSIC - Blood Rad Roses") as AudioClip;
            if(!this.gameObject.GetComponent<AudioSource>().isPlaying)
                this.gameObject.GetComponent<AudioSource>().PlayDelayed(5);
            GameObject.Find("Main Camera").GetComponent<Camera>().orthographicSize = 24;
            foreach (GameObject c in GameObject.FindGameObjectsWithTag("Ally"))
            {
                c.tag = "Enemy";
                c.layer = 8;
                c.transform.FindChild("body").FindChild("head").gameObject.tag = "Head";
                c.transform.FindChild("body").FindChild("head").gameObject.layer = 8;
                for (int i = 0; i < c.transform.childCount-1; i++)
                {
                    c.transform.GetChild(i).gameObject.layer = 8;
                }

                c.GetComponent<EnemyBehavior>().enabled = true;
                c.GetComponent<AllyBehavior2>().enabled = false;
            }
            InvokeRepeating("AddEnemy", 5, 7);
            Invoke("HeroSays", 7f);
            done = true;
        }
	}

    void HeroSays()
    {
        hero.GetComponent<Words>().SayNextWord();
    }
    void AddEnemy()
    {
        if (addCount == 0)
            return;
        GameObject.Instantiate(TrueEnemy, generatePoint.position, Quaternion.identity);
        addCount--;
    }
}
