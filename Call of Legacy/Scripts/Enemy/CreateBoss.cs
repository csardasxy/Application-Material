using UnityEngine;
using System.Collections;

public class CreateBoss : MonoBehaviour {
	public GameObject Boss;
	public float freshtimes=0;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
	
	}
	void OnTriggerEnter(Collider other){
		if (other.tag == "Player" && freshtimes==0) {
			freshtimes++;
			Boss.SetActive (true);
		}
	}
}
