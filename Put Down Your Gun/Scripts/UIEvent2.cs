using UnityEngine;
using System.Collections;

/// <summary>
/// This script related to the final scene. 
/// It is a simple event triggered by the player's choice.
/// 3 different UI events are attached to different game objects in the scene.
/// </summary>

public class UIEvent2 : MonoBehaviour {
    
    public GameObject[] panels;
    [SerializeField]
    GameObject hero ;
    bool die = false;
	// Use this for initialization
	void Start () {
        panels[0].GetComponent<FadeOff>().StartTimer();
	}
	
	// Update is called once per frame
	void Update () {
        if(hero.GetComponent<health>().die && !die)
        {
            die = true;
            panels[1].SetActive(true);
            panels[2].GetComponent<FadeOff>().StartTimer();
        }
	   
	}


}
