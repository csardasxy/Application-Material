using UnityEngine;
using System.Collections;

/// <summary>
/// This script related to the final scene. 
/// It is a simple event triggered by the player's choice.
/// 3 different UI events are attached to different game objects in the scene.
/// </summary>

public class UIEvent3 : MonoBehaviour {
    
    public GameObject[] panels;
    [SerializeField]
    bool die = false;
	// Use this for initialization
	void Start () {
        Invoke("End", 110);
	}
	

    void End()
    {
        panels[0].GetComponent<FadeOff>().StartTimer();
        panels[1].SetActive(true);
    }

}
