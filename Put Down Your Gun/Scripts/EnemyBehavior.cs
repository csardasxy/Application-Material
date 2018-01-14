using UnityEngine;
using System.Collections;
using System;

/// <summary>
/// This script is related to enemies' AI: chasing after the character and shooting at him.
/// Also, these enemies can deal damage to character's allies.
/// And the part of attacking is logically same as Aim_Shoot.cs.
/// </summary>

public class EnemyBehavior : MonoBehaviour {
    [SerializeField]private GameObject player;
    [SerializeField]private float moveSpeed = 5;
    public GameObject[] arms = new GameObject[2];
    public Transform[] shootPoint;
    public GameObject bloodBurst;
    [SerializeField]private float TBA = 4f;
    public int damege = 30;
    private  bool isFaceRight = false;
    private int actualDamege;
    private int bulletCount = 4;
    private int bulletCountNow;
    private float turnSpeed = 5f;
    [SerializeField]private  Transform aimAt;
    private AudioSource EnemyAudio;
    public AudioClip shootClip, reloadClip;
    [SerializeField]private LayerMask mask;
    Ray2D shootRay2D;
    LineRenderer gunLine;
    float shootRange = 100f;
    RaycastHit shootHit;
    RaycastHit2D shootHit2D;
    float effectsDisplayTime = 0.07f;
    float timer, timer2, timer3, waitTime;
    bool canFire = true;

    // Use this for initialization
    void Start () {
        EnemyAudio = this.gameObject.GetComponent<AudioSource>();
        player = GameObject.FindGameObjectWithTag("Player");
        aimAt = player.transform.FindChild("aimAt");
        actualDamege = damege;
        bulletCountNow = bulletCount;
        gunLine = GetComponent<LineRenderer>();
        isFaceRight = this.gameObject.transform.localScale.x < 0? false :true;
        TBA = UnityEngine.Random.Range(4f, 7f);
        waitTime = UnityEngine.Random.Range(0f, 15f);
    }

    // Update is called once per frame
    void Update()
    {
        if(player.GetComponent<health>().die)
        {
            canFire = false;
        }
        timer += Time.deltaTime;
        timer2 += Time.deltaTime;
        timer3 += Time.deltaTime;
        if (timer2 >= TBA && canFire)
        {
            Fire();
        }
        if (timer >= effectsDisplayTime)
        {
            gunLine.enabled = false;
        }
        
    }

    void FixedUpdate()
    {
        if (timer3 > waitTime)
            Move();
        Aim(aimAt.position);
        //Aim(this.transform.position + new Vector3(-10, 3, 0));
    }

    void Move()
    {
        GetComponent<Animator>().SetBool("moveTo", true);
        if (isFaceRight)
            gameObject.GetComponent<Rigidbody2D>().velocity = new Vector3(moveSpeed, gameObject.GetComponent<Rigidbody2D>().velocity.y);
        else
            gameObject.GetComponent<Rigidbody2D>().velocity = new Vector3(-moveSpeed, gameObject.GetComponent<Rigidbody2D>().velocity.y);
    }

    private void Fire()
    {

        //GetComponent<Animator>().SetTrigger("shoot");
        
        EnemyAudio.clip = shootClip;
        EnemyAudio.Play();
        bulletCountNow--;
       
        timer = 0;
        timer2 = 0;
        shootRay2D.origin = shootPoint[1].position;
        shootRay2D.direction = shootPoint[1].position - shootPoint[0].position;
        gunLine.enabled = true;
        gunLine.SetPosition(0, shootRay2D.origin);
        if (Physics2D.Raycast(shootRay2D.origin, shootRay2D.direction, shootRange, mask))
        {
            shootHit2D = Physics2D.Raycast(shootRay2D.origin, shootRay2D.direction, shootRange, mask);
            if (shootHit2D.transform.gameObject.tag == "Player" || shootHit2D.transform.gameObject.tag == "Ally")
            {
                actualDamege = damege;
                if (shootHit2D.collider.gameObject.tag == "Head")
                    actualDamege = damege * 10;
                    shootHit2D.transform.gameObject.GetComponent<health>().TakeDamege(actualDamege);
                GameObject.Instantiate(bloodBurst, shootHit2D.point, Quaternion.Euler(shootRay2D.direction));
            }
            gunLine.SetPosition(1, shootHit2D.point);
            
        }
        else
        {
            gunLine.SetPosition(1, shootRay2D.origin + shootRay2D.direction * shootRange);
        }
        if (bulletCountNow == 0)
            Reload();

    }

    private void Aim(Vector3 position)
    {
        if(position.x - this.transform.position.x > 0 && !isFaceRight ||position.x - this.transform.position.x <= 0 && isFaceRight)
        {
            Flip();
        }
        Vector3 direction = position - transform.position;
        direction.z = 0f;
        direction.Normalize();

        float targetAngle = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg;
        if (targetAngle > 90)
            targetAngle = 180 - targetAngle;
        if (targetAngle < -90)
            targetAngle = -180 - targetAngle;
        for (int i = 0; i < arms.Length; i++)
        {
            arms[i].transform.localRotation = Quaternion.Slerp(arms[i].transform.localRotation, Quaternion.Euler(0, 0, targetAngle), turnSpeed * Time.deltaTime);
        }
    }

    void Reload()
    {
        bulletCountNow = bulletCount;
    }

        public void Flip()
    {
        isFaceRight = !isFaceRight;
        Vector3 scale = this.transform.localScale;
        scale.x *= -1;
        for (int i = 0; i < arms.Length; i++)
        {
            Quaternion rotation = new Quaternion(0,0,0,0);
            arms[i].transform.rotation = rotation;
        }
        this.transform.localScale = scale;
    }
}
