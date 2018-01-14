using UnityEngine;
using System.Collections;
using UnityEngine.UI;

/// <summary>
/// This is attached to the "Character" prefab, and controls the growth of character.
/// </summary>

public class lvlUp : MonoBehaviour {
	public float experience=100f;
	public float current=0f;
	public ParticleSystem par;
	public PlayerHealth player;
	public Animator anim;
    public person pe;
//	public Slider slider;
	// Use this for initialization
	void Start () {
		anim = GetComponent<Animator> ();
		player = GetComponent<PlayerHealth> ();
        pe = GetComponent<person>();
//		slider.value = current;
	}
	
	// Update is called once per frame
	void Update () {
		if (current >= experience) {
			levelup ();
		}
	}
	public void AddExp(float exp){
		current = current + exp;
//		slider.value = current;
	}
	void levelup(){
		anim.SetTrigger ("LevelUp");

        pe.HP += 20;
        pe.MP += 20;
        pe.ATK += 20;
        pe.DEF += 20;
        pe.DEX += 20;
        pe.CRI += 20;
        pe.EVA += 20;
        pe.BLK += 20;

        current = 0;
//		slider.value = current;
		par.Play ();
		player.refresh ();

	}
}
