using UnityEngine;
using System.Collections;

public class closeIntroduce : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}

    public void closeIntro()
    {
        GameObject.Destroy(gameObject.transform.parent.gameObject);
    }
}
