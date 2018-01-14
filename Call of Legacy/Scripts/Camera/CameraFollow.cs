using UnityEngine;
using System.Collections;

public class CameraFollow : MonoBehaviour {
	public GameObject target;
	public float smoothing=5f;
	public Camera mCamrea;
	Vector3 offset;
	Vector3 direction;
	// Use this for initialization
	void Start () {
		
		offset = target.transform.position - transform.position;//distance
		direction= 	transform.eulerAngles-target.transform.eulerAngles;
	}
	
	// Update is called once per frame
	void Update () {
		Vector3 CamPosition = target.transform.position-offset;
		transform.position = Vector3.Slerp (transform.position, CamPosition, smoothing * Time.deltaTime);//Cam move

	}

}
