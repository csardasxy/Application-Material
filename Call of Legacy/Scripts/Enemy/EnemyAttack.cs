using UnityEngine;
using System.Collections;

/// <summary>
/// This controls enemies' attack animation playing 
/// </summary>


public class EnemyAttack : MonoBehaviour {
	public GameObject target;
	public float AttackRate=1f;
	public float Damage=2f;

	private bool attack1=true;
	private Animation anim;
	private PlayerHealth player;
	private EnemyHealth enemy;
	private float timer=0;
	public EnemyMoving enemyMove;
	private bool InRange=false;
    private person pe;

	// Use this for initialization

	void Start () {
		enemyMove = GetComponent<EnemyMoving> ();
		target = GameObject.Find ("Character");
		anim = GetComponent<Animation> ();
        pe = target.GetComponent<person>();
		player = target.GetComponent<PlayerHealth> ();
		enemy = GetComponent<EnemyHealth> ();
	}
	
	// Update is called once per frame
	void Update () {
		timer = timer + Time.deltaTime;
		if(timer>=AttackRate && InRange && enemy.currentHealth>0 ){
			StartCoroutine( attack ());
			}
		if (pe.HPNOW <= 0) {
			enemyMove.enabled = false;
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
			anim.Play ("axe attack");
			if (enemy.currentHealth < 20) {
				anim.PlayQueued ("idle break 1");
			} else {
				anim.PlayQueued ("walk");
			}
			while (attack1) {
				if (anim.IsPlaying ("walk")) {
					player.getDamaged (Damage);
					attack1 = false;
				}
				yield return null;
			}
			attack1 = true;
		}
	}
}
