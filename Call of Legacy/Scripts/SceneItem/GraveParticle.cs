using UnityEngine;
using System.Collections;

/// <summary>
/// This controls particle sys of character's grave
/// </summary>

public class GraveParticle : MonoBehaviour {
	public GameObject target;
	public ParticleSystem[] par;

	private bool refresh=true;
	// Use this for initialization
	void Start () {
		target = GameObject.FindWithTag ("Player");
	}
	
	// Update is called once per frame
	void Update () {
		
	}
	void OnTriggerEnter(Collider other){
		refresh = true;
		if (other.tag == "Player") {
			StartCoroutine( playParticle ());
		}
	}
	void OnTriggerStay(Collider other){
		
	}
	void OnTriggerExit(Collider other){
		if (other.tag == "Player") {
			foreach (ParticleSystem a in par) {
				refresh = false;
				a.Stop ();
			}
		}
	}
	IEnumerator playParticle(){
		while (refresh) {
			
			if (par [1].isStopped) {
				par [1].Play ();
			}
			if (Vector3.Distance (target.transform.position, transform.position) <= 20f) {
				if (par [2].isStopped) {
					par [2].Play ();
				}
			}
			if (Vector3.Distance (target.transform.position, transform.position) > 20f) {
				if (par [2].isPlaying) {
					par [2].Stop();
				}
			}
			if (Vector3.Distance (target.transform.position, transform.position) <= 12f) {
				if (par [0].isStopped) {
					par [0].Play ();
				}
			}
			if (Vector3.Distance (target.transform.position, transform.position) > 12f) {
				if (par [0].isPlaying) {
					par [0].Stop();
				}
			}
			if (Vector3.Distance (target.transform.position, transform.position) <= 7f) {
				if (par [3].isStopped) {
					par [3].Play ();
				}
			}
			if (Vector3.Distance (target.transform.position, transform.position) > 7f) {
				if (par [3].isPlaying) {
					par [3].Stop();
				}
			}
			yield return null;
		}
	}
}
