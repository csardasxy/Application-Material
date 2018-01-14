using UnityEngine;
using System.Collections;
using UnityEngine.SceneManagement;

/// <summary>
/// This contains all the button listeners' functions in this game. 
/// And these functions are attached to buttons in every scene of this game's unity project
/// </summary>

public class ButtonEvent : MonoBehaviour {
    [SerializeField]
    GameObject[] panels;
    public GameObject ConfigPanel;
    public GameObject StartPanel;
    public void StartLv1()
    {
        panels[1].SetActive(true);
        panels[0].SetActive(true);
        panels[0].GetComponent<FadeOff>().StartTimer();
    }

    public void ConfigSwitch()
    {
        ConfigPanel.SetActive(!ConfigPanel.activeSelf);
        StartPanel.SetActive(!StartPanel.activeSelf);
    }

    public void Quit()
    {   
        Application.Quit();
    }

    public void LoadLv1()
    {
        SceneManager.LoadScene("Lv1");
    }

    public void LoadLv2()
    {
        SceneManager.LoadScene("Lv2");
    }

    public void BackToMain()
    {
        SceneManager.LoadScene("Start");
    }

    public void ShowEnd()
    {
        SceneManager.LoadScene("END");
    }
}
