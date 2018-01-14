using UnityEngine;
using System.Collections;

/// <summary>
/// This is used for changing the value of BOSS's health
/// </summary>

public class BossHealth : MonoBehaviour {
	public float CurrentHealth=0f;
	public float MaxHealth=100f;
	public bool IsDied=false;
	public TP_Controler player1;
	public ParticleSystem[] part;
	public lvlUp level;
	public float exp=30f;
	public float SinkingSpeed=1.5f;
	public bool IsActive=false;

	float timer=0f;
	bool IsSinking=false;
	int layer;
	Animation anim;
	// Use this for initialization
	void Start () {
		level = GameObject.FindWithTag ("Player").GetComponent<lvlUp> ();
		player1 = GameObject.FindWithTag ("Player").GetComponent<TP_Controler> ();

		layer = LayerMask.GetMask ("Player");
		CurrentHealth = MaxHealth;
		anim = GetComponent<Animation> ();
		anim.Play ("fight idle break");
		anim.PlayQueued ("run");
	}
	
	// Update is called once per frame
	void Update () {
		timer = timer + Time.deltaTime;
		if (IsSinking && timer>2f) {
			transform.Translate ((-1) * transform.up * SinkingSpeed * Time.deltaTime);//if monster died,then sink
		}
		if (CurrentHealth < 30f) {
			IsActive = true;
		}

	}
	public void GetDamaged(float damage){
		if (IsDied) {
			return;
		}
		if (IsActive) {
			damage = damage / 2;
		}
		if(Physics.Raycast(transform.position,transform.forward,5f,layer)){
			anim.Play ("hit front");
		}
		else{
			anim.Play("hit back");
		}
		anim.PlayQueued("walk");
		CurrentHealth = CurrentHealth - damage;
		if (player1.AttackTimes == 2) {
			part [1].Play ();
		} else {
			part [0].Play ();
		}
		if (CurrentHealth<0) {
			dead ();
		}
	}
	void dead(){
		
			
		anim.Play ("die1");
		IsDied = true;
		level.AddExp (exp);
		GetComponent<CapsuleCollider> ().isTrigger = true;
		GetComponent<Rigidbody> ().isKinematic = true;
		IsSinking = true;
		Destroy (gameObject, 3f);

	}
}
