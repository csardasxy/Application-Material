using UnityEngine;
using System.Collections;

/// <summary>
/// This controls the character's health value change.
/// When the HP is reduced to 0, the character dies and invokes a sequence of releated functions.
/// </summary>

public class CharacterHealth : health {
    [SerializeField]private int hp = 100;
    public AudioClip deathClip;
    private AudioSource PlayerAudio;
	// Use this for initialization
	void Start () {
        PlayerAudio = GetComponent<AudioSource>();
    }
	
    override public void TakeDamege(int damege)
    {
        hp -= damege;
        if (hp <= 0)
            Die();
    }

    override public void Die()
    {
        die = true;
        //play death animation clip.
        gameObject.GetComponent<Animator>().SetBool("Die", true);
        gameObject.GetComponent<Animator>().SetBool("falling", false);
                gameObject.GetComponent<LineRenderer>().enabled = false;
        PlayerAudio.clip = deathClip;
        PlayerAudio.Play();
        //sink character's body by disabling the chllider2D on leg.
        transform.FindChild("legs").gameObject.GetComponent<CircleCollider2D>().enabled = false;
        gameObject.GetComponent<Animator>().SetFloat("speed", 0);
        
        gameObject.GetComponent<Character_controller>().enabled = false;
        gameObject.GetComponent<Aim_Shoot>().enabled = false;
        Invoke("Disabled", 2f);
    }

    override public void Disabled()
    {
        //Disable all the colliders and wait for being destroyed.
        PlayerAudio.enabled = false;
        GetComponent<Rigidbody2D>().isKinematic = true;
        GetComponentInChildren<CircleCollider2D>().enabled = false;
        foreach(Component c in GetComponentsInChildren<BoxCollider2D>())
        {
            c.GetComponent<BoxCollider2D>().enabled = false;
        }
        GetComponent<Rigidbody2D>().MovePosition(new Vector2(transform.position.x, transform.position.y - 0.5f));
    }
	// Update is called once per frame
	void Update () {
	
	}
}
