using UnityEngine;
using System.Collections;

/// <summary>
/// This controls ally's heath change during the gameplay.
/// </summary>

public class AllyHealth : health
{
    [SerializeField]
    private int hp = 100;
    public AudioClip deathClip;
    private AudioSource EnemyAudio;
    [SerializeField]
    private GameObject blood;
    // Use this for initialization
    void Start()
    {
        EnemyAudio = GetComponent<AudioSource>();
        
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
        //Play the death animation
        gameObject.GetComponent<Animator>().SetBool("Die", true);
        gameObject.GetComponent<LineRenderer>().enabled = false;
        //Play the death audio
        EnemyAudio.clip = deathClip;
        EnemyAudio.Play();
        transform.FindChild("legs").gameObject.GetComponent<CircleCollider2D>().enabled = false;
        foreach(var c in gameObject.GetComponents<MonoBehaviour>())
        {
            c.enabled = false;
        }
        //Initialize blood particle.
        GameObject.Instantiate(blood, this.transform.position + new Vector3(0,-6,0), Quaternion.identity);
        Invoke("Disabled", 2f);
    }

    override public void Disabled()
    {
        //Disable the collider2D attached and wait for being destroyed.
        EnemyAudio.enabled = false;
        GetComponent<Rigidbody2D>().isKinematic = true;
        foreach (var c in GetComponentsInChildren<Collider2D>())
        {
            c.enabled = false;
        }

    }

}
