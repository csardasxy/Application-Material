using UnityEngine;
using System.Collections;

/// <summary>
/// logic of loading game
/// </summary>

public class LoadScene : MonoBehaviour {

    public float f = 0.6f;
	// Use this for initialization
	void Start () {
	    
	}
	
	// Update is called once per frame
	void Update () {
        GetComponent<SpriteRenderer>().material.SetFloat("_Progress", f);
	}
}
