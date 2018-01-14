using UnityEngine;
using System.Collections;

/// <summary>
/// This script is used for controlling one of enemies' skills : Bomb
///     initialize a round Bomb and push it forward, this Bomb will hit the first enemy it reaches.
/// </summary>


public class Bomb : MonoBehaviour {
	public GameObject target;
	public float AttackRate=4f;
	public float Damage=10f;
	public GameObject Bomb1;
	public EnemyMoving move;

	private bool attack1=true;
	private Animation anim;
	private PlayerHealth player;
	private EnemyHealth enemy;
    private person pe;
	private float timer=0;
	private bool InRange=false;

	// Use this for initialization

	void Start () {
		move = GetComponent<EnemyMoving> ();
		target = GameObject.Find ("Character");
		anim = GetComponent<Animation> ();
		player = target.GetComponent<PlayerHealth> ();
        pe = target.GetComponent<person>();
		enemy = GetComponent<EnemyHealth> ();
	}

	// Update is called once per frame
	void Update () {
		if (InRange) {
			move.enabled = false;
		} else {
			move.enabled = true;
		}
		timer = timer + Time.deltaTime;
		if(timer>=AttackRate && InRange && enemy.currentHealth>0 ){
			StartCoroutine( attack ());
		}
		if (pe.HPNOW <= 0) {
			anim.Play ("idle");
		}
	}
	void OnTriggerEnter(Collider other){

		if (other.gameObject == target) {
			InRange = true;
		}
	}
	void OnTriggerExit(Collider other){
		if (other.gameObject == target) {
			InRange = false;
		}
	}
	IEnumerator attack(){
		timer = 0f;
		if (pe.HPNOW > 0) {
			anim.Play ("casting A");
			GameObject a = Instantiate (Bomb1, new Vector3(transform.position.x,transform.position.y+1.5f,transform.position.z), Quaternion.identity) as GameObject;
			Vector3 direction = target.transform.position - a.transform.position;
			a.GetComponent<Rigidbody> ().AddForce(direction,ForceMode.Impulse);
			float time = 0f;
			if (enemy.currentHealth < 20) {
				anim.PlayQueued ("idle break 1");
			} else {
				anim.PlayQueued ("walk");
			}
			while (attack1) {
				time = time + Time.deltaTime;
				RaycastHit hitinfo;
				if (time == 2f && Vector3.Distance(a.transform.position,player.transform.position)<=3f) {
					
					player.getDamaged (Damage);
					attack1 = false;

				}
				yield return null;
			}
			attack1 = true;
		}
	}
}
