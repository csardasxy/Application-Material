using UnityEngine;
using System.Collections;

/// <summary>
/// This script controls enemies' moving action
/// </summary>

public class EnemyMoving : MonoBehaviour {
	private Animation anim;
	public EnemyController controller;
	private RaycastHit hit;
	private LayerMask layer;
	public bool InRange=false;

	void Awake(){
		controller = GetComponentInParent<EnemyController> ();
		layer = LayerMask.GetMask ("Player");
		anim=GetComponent<Animation> ();
	}
	void Update(){
		

        // if the hero is in an enemy's range of attack, this enemy will chase and attack him.
		InRange = controller.InRange;

		if (controller && InRange) {
			
			Vector3 direction = new Vector3((controller.target.transform.position-transform.position).x,0,(controller.target.transform.position-transform.position).z);
			Quaternion target = Quaternion.LookRotation (direction);
			transform.rotation=Quaternion.RotateTowards(transform.rotation,target,Time.deltaTime*100f);
			Vector3 relativePos = steer () * Time.deltaTime;//speed vector. steer() used to caculate a speed;

			if(relativePos!=Vector3.zero){
				GetComponent<Rigidbody> ().velocity = relativePos;

			}
			float speed = GetComponent<Rigidbody> ().velocity.magnitude;//value of speed;
			if (speed > controller.maxVelocity) {//controller values a minSpeed and a maxSpeed
				GetComponent<Rigidbody> ().velocity = GetComponent<Rigidbody> ().velocity.normalized * controller.maxVelocity;

			} else if (speed < controller.minVelocity) {
				
				GetComponent<Rigidbody> ().velocity = GetComponent<Rigidbody> ().velocity.normalized * controller.minVelocity;
			}

		}
	}

    //use this to caculate the speed;
    private Vector3 steer(){
		//Seperation,Alignment,Cohesion
		Vector3 center=controller.EnemyCenter-transform.position;//cohesion
		Vector3 velocity=controller.EnemyVelocity-GetComponent<Rigidbody>().velocity;//alignment
		Vector3 follow=controller.target.localPosition-transform.position;//follow leader or player
	
		Vector3 seperation=Vector3.zero;//seperation

		foreach (EnemyMoving enemy in controller.EnemyList) {
			if (enemy != this) {
				Vector3 relativePos = transform.position - enemy.transform.position;

				seperation = seperation + relativePos / (relativePos.sqrMagnitude);
			}
		}

		//randomize
		Vector3 randomize=new Vector3((Random.value*2)-1,(Random.value*2)-1,(Random.value*2)-1);
		randomize = randomize.normalized;
		return (controller.centerWeight * center + controller.velocityWeight * velocity + controller.seperationWeight * seperation +
		controller.followWeight * follow + controller.randomizeWeight * randomize);
	//calculate the speed with weights
	}
}
