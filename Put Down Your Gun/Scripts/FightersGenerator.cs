using UnityEngine;
using System.Collections;

/// <summary>
/// This script can generate fighters in the background of game's scene.
/// </summary>

public class FightersGenerator : MonoBehaviour {
    float waitTime;
    float minWaitTime = 5f, maxWaitTime = 10f, minY = 8f, maxY = 14, flySpeed = 25f;
    public GameObject fighters;
	// Use this for initialization
	void Start () {
        waitTime = Random.Range(minWaitTime, maxWaitTime);
        InvokeRepeating("GenerateFighter", waitTime, waitTime);
	}
	
	// Update is called once per frame
	void Update () {
	    
	}

    void GenerateFighter()
    {
        float rY = Random.Range(minY, maxY);
        GameObject f = Instantiate(fighters, new Vector3(transform.position.x, rY, transform.position.z), Quaternion.identity) as GameObject;
        f.GetComponent<Rigidbody2D>().velocity = new Vector2(flySpeed,0);
        waitTime = Random.Range(minWaitTime, maxWaitTime);
    }
}
