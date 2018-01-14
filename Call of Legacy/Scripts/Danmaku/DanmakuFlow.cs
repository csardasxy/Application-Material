using UnityEngine;
using System.Collections;
using UnityEngine.UI;

/// <summary>
/// This script controls the displayment of danmaku during the game
/// </summary>

public class DanmakuFlow : MonoBehaviour {

    public float SpeedRate = 0.25f;
    public float SpeedOffset = 5.5f;
    public float Speed = 15.5f;

    private static float canvasH;
    private RectTransform rect;
    private string text;

	// Use this for initialization
	void Start () {
        rect = GetComponent<RectTransform>();
        text = GetComponent<Text>().text;
        RectTransform can = GameObject.FindGameObjectWithTag("DanmakuCanvas").GetComponent<RectTransform>();
        canvasH = can.sizeDelta.x;
        float y = Random.Range(can.sizeDelta.y / 2, can.sizeDelta.y - 20);
        rect.position = new Vector3(can.sizeDelta.x + 250, y, 0);
    }
	
	// Update is called once per frame
	void Update () {
        rect.position -= new Vector3(1, 0, 0) * Time.deltaTime * (SpeedRate * text.Length + SpeedOffset) * Speed;
        if (-rect.position.x + 250 >= canvasH) {
            Destroy(gameObject);
        }
	}
}
