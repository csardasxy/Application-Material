using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UI;

/// <summary>
/// Interact with the cloud server and show the danmaku in game
/// </summary>
public class DanmakuSystem : MonoBehaviour {

    public Color color = new Color(0.8f, 0.8f, 0.8f);
    public float DanmakuRate = 1.0f;
    public int fontSize = 14;

    public static float Offset = 5.0f;
    public static Queue<Danmaku> danmakuQueue = new Queue<Danmaku>();
    public Text danmakuText;
    public static HashSet<string> idSet = new HashSet<string>();
    public Slider slider;
    public InputField input;

    private Cloud cloud;
    private GameObject canvas;
    private GameObject player;
    private GameController gc;

    // Use this for initialization
    void Start () {
        canvas = GameObject.FindGameObjectWithTag("DanmakuCanvas");
        cloud = GameObject.FindGameObjectWithTag("GameController").GetComponent<Cloud>();
        player = GameObject.FindGameObjectWithTag("Player");
        gc = GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>();
        InvokeRepeating("GetDanmaku", 2, DanmakuRate);
	}
	
	// Update is called once per frame
	void Update () {
        float x = player.transform.position.x;
        float y = player.transform.position.y;
        float z = player.transform.position.z;
        cloud.PullDanmaku(gc.CurrentLevel, x, y, z);
	}

    private void GetDanmaku() {
        if (danmakuQueue.Count > 0) {
            Danmaku danmaku = danmakuQueue.Dequeue();
            Text d = Instantiate(danmakuText);
            d.text = danmaku.Content;
            d.color = new Color((float)danmaku.ColorR.Get(), (float)danmaku.ColorG.Get(), (float)danmaku.ColorB.Get());
            d.fontSize = danmaku.FontSize.Get();
            d.transform.SetParent(canvas.transform);
        }
    }

    public void ChangeEnable()
    {
        if (enabled)
        {
            CancelInvoke("GetDanmaku");
            danmakuQueue.Clear();
            idSet.Clear();
            enabled = false;
        }
        else
        {
            enabled = true;
            InvokeRepeating("GetDanmaku", 0, DanmakuRate);
        }
    }

    public void ChangeRate() {
        float rate = 1.0f/slider.value;
        CancelInvoke("GetDanmaku");
        DanmakuRate = rate;
        InvokeRepeating("GetDanmaku", 0, DanmakuRate);
    }

    public void changeFontSize(int size)
    {
        fontSize = size;
    }

    public void changeColorR(float r)
    {
        color.r = r;
    }

    public void changeColorG(float g)
    {
        color.g = g;
    }

    public void changeColorB(float b)
    {
        color.b = b;
    }

    public void sendDanmaku()
    {
        string text = input.text;
        if (text.Length <= 0)
            return;

        cloud.PushDanmaku(text, player.transform.position.x, player.transform.position.y, player.transform.position.z, gc.CurrentLevel, color, fontSize);
    }
}
