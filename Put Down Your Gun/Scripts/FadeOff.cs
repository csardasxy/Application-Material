using UnityEngine;
using UnityEngine.UI;
using System.Collections;

/// <summary>
/// It controls the images to fade out from the view.
/// </summary>

public class FadeOff : MonoBehaviour {
    [SerializeField]
    private float startDelay = 3f, timer;
    [SerializeField]
    bool over = false;
    bool start = false;
	// Use this for initialization
	void Start () {
        timer = startDelay;
	}
	
	// Update is called once per frame
	void Update () {
        if(timer > 0 && start)
            timer -= Time.deltaTime;
        if (!over && timer <= 0)
        {
            StartFade();
        }
    }

    void StartFade()
    {

        var a = gameObject.GetComponent<Image>().color.a;
        var r = gameObject.GetComponent<Image>().color.r;
        var g = gameObject.GetComponent<Image>().color.g;
        var b = gameObject.GetComponent<Image>().color.b;
        if (a <= 0)
        {
            this.gameObject.SetActive(false);
            over = true;
            start = false;
            return;
        }
        
        //The alpha value decreases with the time flow.
        a = a - 0.01f;
        gameObject.GetComponent<Image>().color = new Color(r, g, b, a);
    }

    public void StartTimer()
    {
        this.gameObject.SetActive(true);
        timer = startDelay;
        start = true;
        over = false;
        var a = gameObject.GetComponent<Image>().color.a;
        var r = gameObject.GetComponent<Image>().color.r;
        var g = gameObject.GetComponent<Image>().color.g;
        var b = gameObject.GetComponent<Image>().color.b;
        gameObject.GetComponent<Image>().color = new Color(r, g, b, 1f);
    }
}
