using UnityEngine;
using System.Collections;

/// <summary>
/// This is added on each enemy's initializing points
/// </summary>

public class CreateMonster : MonoBehaviour {
	public GameObject[] enemy;
	int i=0;
	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}

	void OnTriggerEnter(Collider other){
		
		if (other.gameObject.name == "Character") {
			
			if (i < enemy.Length) {
				StartCoroutine (refreshMonster ());
			}
		}
	}
	IEnumerator refreshMonster(){
		
		for (; i < enemy.Length; i++) {
			enemy [i].SetActive (true);
			yield return new WaitForSeconds (1f);
		}
	}
}
