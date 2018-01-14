using UnityEngine;
using System.Collections;

public class DanmakuSending : MonoBehaviour {
    public TP_Animator ta;
	// Use this for initialization
	void Start () {
        ta = GameObject.FindGameObjectWithTag("Player").GetComponent<TP_Animator>();
    }
	
	// Update is called once per frame
	void Update () {
	
	}

    public void showInputField()
    {
        gameObject.SetActive(!gameObject.activeSelf);
        
    }
}
