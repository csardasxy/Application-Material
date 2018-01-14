using UnityEngine;
using System.Collections;
using UnityEngine.SceneManagement;

/// <summary>
/// show/hide of setting panel
/// </summary>

public class Setting : MonoBehaviour {

	// Use this for initialization
	void Start () {
	    
	}
	
	// Update is called once per frame
	void Update () {
	
	}

    public void showPausePanel()
    {
        gameObject.SetActive(!gameObject.activeSelf);
    }
    public void showSettingPanel()
    {
        gameObject.SetActive(!gameObject.activeSelf);
    }

    public void Exit()
    {
        SceneManager.LoadScene("START");
    }

    public void Quit()
    {
        Application.Quit();
    }
}
