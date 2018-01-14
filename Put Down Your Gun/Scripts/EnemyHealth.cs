using UnityEngine;
using System.Collections;

/// <summary>
/// This contains functions related to enemy's health (get damaged and die).
/// </summary>

public class Enemy_health : health
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
        gameObject.GetComponent<Animator>().SetBool("Die", true);
        gameObject.GetComponent<LineRenderer>().enabled = false;
        EnemyAudio.clip = deathClip;
        EnemyAudio.Play();
        transform.FindChild("legs").gameObject.GetComponent<CircleCollider2D>().enabled = false;
        gameObject.GetComponent<MonoBehaviour>().enabled = false;
        GameObject.Instantiate(blood, this.transform.position + new Vector3(0, -1F, 0), Quaternion.identity);
        gameObject.GetComponent<Rigidbody2D>().MovePosition(this.transform.position + new Vector3(0, -0.5f, 0));
        Invoke("Disabled", 2f);
    }

    override public void Disabled()
    {
        EnemyAudio.enabled = false;
        GetComponent<Rigidbody2D>().isKinematic = true;
        foreach (var c in GetComponentsInChildren<Collider2D>())
        {
            c.enabled = false;
        }
    }
    // Update is called once per frame
    void Update()
    {

    }
}
