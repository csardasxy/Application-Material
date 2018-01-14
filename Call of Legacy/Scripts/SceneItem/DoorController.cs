using UnityEngine;
using System.Collections;

/// <summary>
/// This script controls auto open/close logic of doors in this game's scene
/// </summary>
public class DoorController : MonoBehaviour {
	public GameObject target;
	LayerMask layer;
	bool IsOpen=false;
	Animation anim;
	// Use this for initialization
	void Start () {
		
		target = GameObject.FindWithTag ("Player");
		layer = LayerMask.GetMask ("Player");
		anim = GetComponent<Animation> ();
	}
	
	// Update is called once per frame
	void Update () {
		if (Vector3.Distance (target.transform.position, transform.position) <= 6f) {
			
			anim.Play ("door-open");

			IsOpen = true;
		} else if (IsOpen == true) {
			
			anim.Play ("door-close");
			IsOpen = false;
		}
	}
}
