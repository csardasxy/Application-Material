using UnityEngine;
using System.Collections;
using UnityEngine.SceneManagement;

/// <summary>
/// This script ensures the smooth change between different game scenes.
/// </summary>

public class LevelSwitch : MonoBehaviour {
    [SerializeField]
    UIEvent1 eventManager;
	// Use this for initialization
    void OnTriggerEnter2D(Collider2D other)
    {
        if(other.gameObject.name == "Character")
        {
            if(SceneManager.GetActiveScene().name == "Lv1")
            {
                eventManager.panels[2].GetComponent<FadeOff>().StartTimer();
                eventManager.panels[3].SetActive(true);
            }
        }
    }
}
