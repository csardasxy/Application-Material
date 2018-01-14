using UnityEngine;
using System.Collections;

/// <summary>
/// This script controls the BOSS's behaviour about attacking and the related animation playing
/// </summary>

public class BossAttack : MonoBehaviour {
	public BossHealth boss;
	public PlayerHealth player;
	public BossMoving move;
	public float MinDamage=5f;
	public float MaxDamage = 10f;

	public float MaxAttackRate=0.5f;
	public float MinAttackRate=2f;

	float timer1=0f;
	float currentAttackDamage;
	bool attack1=true;
	float timer=5f;
	float currentAttackRate;
	Animation anim;
	bool InRange=false;
    person pe;
	// Use this for initialization
	void Start () {
		move = GetComponent<BossMoving> ();
		currentAttackDamage = MinDamage;
		boss = GetComponent<BossHealth> ();
		currentAttackRate = MinAttackRate;
		player = GameObject.FindWithTag ("Player").GetComponent<PlayerHealth>();
        pe= GameObject.FindWithTag("Player").GetComponent<person>();
        anim = GetComponent<Animation> ();
	}
	
	// Update is called once per frame
	void Update () {
		moveToward ();
		if (boss.IsActive) {
			
			currentAttackRate = MaxAttackRate;
			currentAttackDamage = MaxDamage;
		}

		if (InRange) {
			timer = timer + Time.deltaTime;
			move.enabled = false;

			if (timer >= currentAttackRate && boss.IsDied == false) {
				StartCoroutine (attack ());
			}
			if (pe.HPNOW <= 0) {
				anim.Play ("idle");
			}
		} else {
			timer1 = timer1 + Time.deltaTime;
			if (timer1 >= 1f && move.enabled==false) {
				anim.Stop ();
				move.enabled = true;

			}
		}
	}
	IEnumerator attack ()
	{
		timer = 0f;
		if (pe.HPNOW > 0) {
			if (boss.IsActive) {
				anim.Play ("attack3");
				anim.PlayQueued ("fight idle to shot");
			} else {
				
				anim.Play ("attack1");
				anim.PlayQueued ("fight idle to shot");
			}

			while (attack1) {
				if (anim.IsPlaying ("fight idle to shot")) {
					player.getDamaged (currentAttackDamage);
					attack1 = false;
				}
				yield return null;
			}
			attack1 = true;
		}
	}
	void moveToward(){
		Vector3 direction = new Vector3((player.transform.position-transform.position).x,0,(player.transform.position-transform.position).z);
		Quaternion target = Quaternion.LookRotation (direction);
		transform.rotation=Quaternion.RotateTowards(transform.rotation,target,Time.deltaTime*500f);
	}
	void OnTriggerEnter(Collider other){
		
		timer1 = 0;
		if (other.tag == "Player") {
			InRange = true;
		}
	}
	void OnTriggerExit(Collider other){
		if (other.tag == "Player") {
			InRange = false;
		}
	}

}
