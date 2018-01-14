using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// This controls enemies moving behaviour
/// </summary>

public class EnemyController : MonoBehaviour {
	public float minVelocity=1f;
	public float maxVelocity=5f;  //min/max speed
	public EnemyMoving[] EnemyList;
	public bool InRange = false;

	//weight,quan zhong,larger weight,stick closer
	public float centerWeight=1f;

	public float velocityWeight=1f;//alignment

	public float seperationWeight=1f;//how far one enemy and another

	public float followWeight = 1f;//how far should the Enemy follow the Leader

	public float randomizeWeight=1f;

	public Transform target;

	Animation anim;
	float timer=0f;
	bool play=false;
	internal Vector3 EnemyCenter;
	internal Vector3 EnemyVelocity;

	// Use this for initialization
	void Start () {
		anim = GetComponentInChildren<Animation> ();
		target = GameObject.FindWithTag ("Player").transform;

		foreach (EnemyMoving enemy in EnemyList) {
			enemy.controller = this;

		}
	}
	
	// Update is called once per frame
	void Update () {
		if (anim.IsPlaying ("idle break 2")) {
			return;
		}
		EnemyList = GetComponentsInChildren<EnemyMoving>();
		Vector3 center = Vector3.zero;
		Vector3 velocity = Vector3.zero;
		foreach (EnemyMoving enemy in EnemyList) {
			center = center + enemy.transform.position;
			velocity = velocity + enemy.GetComponent<Rigidbody> ().velocity;
		}
		EnemyCenter = center / EnemyList.Length;
		EnemyVelocity = velocity / EnemyList.Length;

		if (Vector3.Distance (EnemyCenter, target.position) <= 15f) {
			InRange = true;
			centerWeight = 100f;
			followWeight = 50f;
		}
		if(Vector3.Distance (EnemyCenter, target.position) <= 10f) {
			velocityWeight = 0;
			centerWeight = 0;
			followWeight = 100f;
		} else {

			centerWeight = 100;
		}
	}
	public void setTarget(Transform transform){
		target = transform;
	}
}
