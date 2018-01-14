using UnityEngine;
using System.Collections;

public class DoorOpen : MonoBehaviour {
	LayerMask layer1;
	LayerMask layer2;
	bool IsOpen=false;
	Animation anim;
	// Use this for initialization
	void Start () {
		anim = GetComponent<Animation> ();
		layer1 = LayerMask.GetMask ("Player");

	}
	
	// Update is called once per frame
	void Update () {
		RaycastHit hit;
		if (Physics.SphereCast (transform.position, 3f, transform.forward, out hit ,3f,layer1)) {
			IsOpen = true;

			anim.Play ("Dragon_door_open_effects_02");
		} else if (IsOpen == true) {
			anim.Play ("Dragon_door_open_effects_01");

		}
	}
}
