using UnityEngine;
using UnityEngine.UI;
using System.Collections;

/// <summary>
/// This script is related to the commander's behaviour in the second scene.
/// </summary>

public class AllyBehavior3 : MonoBehaviour {
    [SerializeField]
    private GameObject player;
    [SerializeField]
    private float moveSpeed;
    public GameObject[] arms = new GameObject[2];
    public Transform[] shootPoint;
    public GameObject bloodBurst;
    [SerializeField]
    private float TBA = 4f;
    public int damege = 30;
    private bool isFaceRight = false;
    private int actualDamege;
    private int bulletCount = 4;
    private int bulletCountNow;
    private float turnSpeed = 5f;
    [SerializeField]
    private Transform aimAt;
    private AudioSource AllyAudio;
    public AudioClip shootClip, reloadClip;
    [SerializeField]
    private LayerMask mask;
    Ray2D shootRay2D;
    LineRenderer gunLine;
    float shootRange = 100f;
    RaycastHit shootHit;
    RaycastHit2D shootHit2D;
    float effectsDisplayTime = 0.07f;
    float timer, timer2, timer3;
    [SerializeField]
    TextMesh text;
    // Use this for initialization
    void Start()
    {
        AllyAudio = this.gameObject.GetComponent<AudioSource>();
        player = GameObject.Find("Character");
        actualDamege = damege;
        bulletCountNow = 1;
        gunLine = GetComponent<LineRenderer>();
        isFaceRight = true;
        TBA = UnityEngine.Random.Range(4f, 7f);
    }

    // Update is called once per frame
    void Update()
    {
        timer += Time.deltaTime;
        timer2 += Time.deltaTime;
        if (timer >= effectsDisplayTime)
        {
            gunLine.enabled = false;
        }

    }

    void FixedUpdate()
    {
        Aim(aimAt.position);
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

        AllyAudio.clip = shootClip;
        AllyAudio.Play();
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
            if (shootHit2D.transform.gameObject.tag == "Enemy")
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

    }

    private void Aim(Vector3 position)
    {
        if (position.x - this.transform.position.x > 0 && !isFaceRight || position.x - this.transform.position.x <= 0 && isFaceRight)
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

    void OnTriggerEnter2D(Collider2D c)
    {
        if(c.gameObject.name == "Character")

        {
            aimAt = c.gameObject.transform.FindChild("body").FindChild("head");
            text.text = "YOU! kill her ! ";
            
            this.gameObject.GetComponent<Words>().timer = 0;
            Invoke("WaitForReply", 2f);
        }
    }

    void WaitForReply()
    {
        player.GetComponent<Words>().Reply(this.gameObject);
    }

    private void Flip()
    {
        isFaceRight = !isFaceRight;
        Vector3 scale = this.transform.localScale;
        scale.x *= -1;
        for (int i = 0; i < arms.Length; i++)
        {
            Quaternion rotation = new Quaternion(0, 0, 0, 0);
            arms[i].transform.rotation = rotation;
        }
        this.transform.localScale = scale;
    }
}
