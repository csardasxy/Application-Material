using UnityEngine;
using System.Collections;

public class autodestroy : MonoBehaviour {
    public float waitTime = 1f;
	// Use this for initialization
	void Start () {
        GameObject.Destroy(this.gameObject, waitTime);
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
