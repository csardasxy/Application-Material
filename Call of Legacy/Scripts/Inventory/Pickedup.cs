using UnityEngine;
using System.Collections;

/// <summary>
/// This controls the dropout of dead enemies and functions related
/// </summary>

public class Pickedup : MonoBehaviour {
	private float a;
	private float b;
	private float c;
	private float d;

    public items2 material;

	// Use this for initialization
	void Start () {
		a = Random.value;
		b = Random.value;
		c = Random.value;
        d = Random.value;
        material = GameObject.FindGameObjectWithTag("items2").GetComponent<items2>();
    }
	
	// Update is called once per frame
	void Update () {
	
	}

    // If the hero entered the sphere trigger attached on the item, This will be added in hero's inventory
	void OnTriggerEnter(Collider other){
        a = Random.value;
        b = Random.value;
        c = Random.value;
        d = Random.value;
        //randomize dropout's type
        if (other.gameObject.tag == "Player")
        {
            if (a <= 0.5)
            {
                if (d < 0.8)
                    material.AddItem(30, Random.Range(0, 7));
                if (b < 0.5)
                    material.AddItem(31, Random.Range(1, 3));
                if (c < 0.3)
                    material.AddItem(32, Random.Range(1, 2));
            }

            if (a > 0.4 && a <= 0.7)
            {
                if (d < 0.8)
                    material.AddItem(33, Random.Range(0, 7));
                if (b < 0.5)
                    material.AddItem(34, Random.Range(1, 3));
                if (c < 0.3)
                    material.AddItem(35, Random.Range(1, 2));
            }

            if (a >= 0.5 && a <= 1.0)
            {
                if (d < 0.8)
                    material.AddItem(36, Random.Range(0, 7));
                if (b < 0.5)
                    material.AddItem(37, Random.Range(1, 3));
                if (c < 0.3)
                    material.AddItem(38, Random.Range(1, 2));
            }
            GameObject.Destroy(gameObject);
        }
        
	}
}
