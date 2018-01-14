using UnityEngine;
using System.Collections;

/// <summary>
/// This script controls the moving mode of the BOSS
/// </summary>

public class BossMoving : MonoBehaviour {
	public BossHealth health;
	public PlayerHealth player;
	public float MaxSpeed = 5f;
	public float NormalSpeed=3f;

	Animation anim;
	float currentSpeed;
	// Use this for initialization
	void Start () {
		anim = GetComponent<Animation> ();
		currentSpeed = NormalSpeed;
		health = GetComponent<BossHealth> ();
		player = GameObject.FindWithTag ("Player").GetComponent<PlayerHealth> ();
	}
	
	// Update is called once per frame
	void Update () {
		if (anim.IsPlaying ("fight idle break")) {
			return;
		}
		if (health.CurrentHealth > 0f) {
			Vector3 direction = player.transform.position - transform.position;
			direction.y = 0;
			Quaternion target = Quaternion.LookRotation (direction);
			transform.rotation = Quaternion.RotateTowards (transform.rotation, target, Time.deltaTime * 300f);
			if (health.IsActive == true) {
				currentSpeed = MaxSpeed;
				anim.PlayQueued("run fast");
			} else {
				anim.PlayQueued ("run");
			}
			transform.Translate (-transform.forward*currentSpeed*Time.deltaTime,Space.Self);
		}
	}
}
