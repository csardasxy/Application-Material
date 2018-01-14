using UnityEngine;
using System.Collections;
using UnityEngine.UI;

/// <summary>
/// This controls damage logic of hero's health
/// </summary>
public class PlayerHealth : MonoBehaviour {
	public bool takeDamaged=false;

	public ParticleSystem par;

    person pe;
    TP_Animator player;
	LayerMask layer;

	Animator anim;
	// Use this for initialization
	void Start () {
		player = GetComponent<TP_Animator> ();
		layer=LayerMask.GetMask("Monster");
        pe = GetComponent<person>();
		anim = GetComponent<Animator> ();
	}
	
	public void  getDamaged(float damage){
        damage = damage * (150.0f / pe.DEF);
		if (Physics.Raycast (transform.position, transform.forward, 100f, layer) && player.State == TP_Animator.CharacterState.Defending) {
			anim.SetTrigger ("DefendAttack");

			StartCoroutine (defending ());

			return;
		}
		anim.SetTrigger ("hurt");
		pe.HPNOW = pe.HPNOW - (int)damage;
		takeDamaged = true;
		if (pe.HPNOW <= 0 && player.State != TP_Animator.CharacterState.Dead) {
			died ();
		}
	}
	void died(){
        TP_Animator.Instance.Die();
	}
	public void refresh(){
        pe.HPNOW = pe.HP;
	}

    // if the hero is defending using his shield, the damage can be reduced
	IEnumerator defending(){
		while (TP_Animator.Instance.State==TP_Animator.CharacterState.Defending) {
			if (anim.GetCurrentAnimatorStateInfo (0).IsName ("DefendAttack")) {
				Debug.Log ("a");
				par.Play ();
			}
			yield return null;
		}
	}

}
