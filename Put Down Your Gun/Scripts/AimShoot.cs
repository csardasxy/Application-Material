using UnityEngine;
using System.Collections;

/// <summary>
/// This can enable player aim enemies by moving mouse, and shoot enemies by clicking the mouse's left button. 
/// </summary>

public class AimShoot : MonoBehaviour {

    public GameObject[] arms = new GameObject[2];
    public float turnSpeed = 3.5f;
    public Transform[] shootPoint;
    public GameObject bloodBurst;
    public float TBA = 1f;
    public int damege = 30;
    private int actualDamege;
    private int bulletCount = 12;
    private int bulletCountNow;
    private AudioSource PlayerAudio;
    public AudioClip shootClip, reloadClip;
    [SerializeField]LayerMask mask;
    Ray shootRay;
    Ray2D shootRay2D;
    LineRenderer gunLine;
    float shootRange = 200f;
    RaycastHit shootHit;
    RaycastHit2D shootHit2D;
    float effectsDisplayTime = 0.07f;
    float timer, timer2;
    public bool canShoot = true;
    
    // Use this for initialization
    void Start () {
        gunLine = GetComponent<LineRenderer>();
        PlayerAudio = GetComponent<AudioSource>();
        actualDamege = damege;
        bulletCountNow = bulletCount;
	}
    
    //Get mouse's screen position and update character sprite's aiming direction.
    void Aiming()
    {
        Vector3 worldPos = Camera.main.ScreenToWorldPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y, -Camera.main.transform.position.z));
        Vector3 direction = worldPos - transform.position;
        direction.z = 0f;
        direction.Normalize();

        //Calculate the rotate angle of character's gun
        float targetAngle = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg;
        if (targetAngle > 90)
            targetAngle = 180 - targetAngle;
        if(targetAngle< -90)
            targetAngle = -180 - targetAngle;
        for (int i = 0; i < arms.Length; i++)
        {
            arms[i].transform.localRotation = Quaternion.Slerp(arms[i].transform.localRotation, Quaternion.Euler(0, 0, targetAngle), turnSpeed * Time.deltaTime);
        }
    }
    // Update is called once per frame
    void FixedUpdate () {
        Aiming();
       
	}

    void Shooting()
    {
        //Initialize a straight thin line that represent the bullet's trace.
        //Before doing this, the start and end position of the line should be figured out.
        timer = 0;
        shootRay.origin = shootPoint[1].position;
        shootRay.direction = shootPoint[1].position - shootPoint[0].position;
        gunLine.enabled = true;
        gunLine.SetPosition(0, shootRay.origin);
        if(Physics.Raycast(shootRay, out shootHit, shootRange, mask))
        {
            gunLine.SetPosition(1, shootHit.point);
        }
        else
        {
            gunLine.SetPosition(1, shootRay.origin + shootRay.direction * shootRange);
        }
    }

    void Shooting2D()
    {
        //Make a raycast and try to find is any enemy was hitted by this bullet.
        GetComponent<Animator>().SetTrigger("shoot");
        PlayerAudio.clip = shootClip;
        PlayerAudio.Play();
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
            //To find if the hitted object is enemy, if it is, then the bullet can deal damage to this object.
            if(shootHit2D.transform.gameObject.tag == "Enemy")
            {
                actualDamege = damege;
                //If this bullet hitted a enemy's head, then it can cause more damage.
                if (shootHit2D.collider.gameObject.tag == "Head")
                    actualDamege = damege * 10;
                shootHit2D.transform.gameObject.GetComponent<health>().TakeDamege(actualDamege);
                GameObject.Instantiate(bloodBurst, shootHit2D.point, Quaternion.Euler(shootRay2D.direction));
            }
            gunLine.SetPosition(1, shootHit2D.point);
            //If the bullet hitted a dead body, then a blood particle will be initialized at the hit spot.
            if (shootHit2D.transform.gameObject.tag == "Dead")
                GameObject.Instantiate(bloodBurst, shootHit2D.point, Quaternion.Euler(shootRay2D.direction));
        }
        else
        {
            gunLine.SetPosition(1, shootRay2D.origin + shootRay2D.direction * shootRange);
        }

        //If the character has used up all the bullets loaded, he will spend time reloading his gun.
        if (bulletCountNow == 0)
            Reload();
    }

    void Reload()
    {
        bulletCountNow = bulletCount;
        PlayerAudio.clip = reloadClip;
        PlayerAudio.Play();
        GetComponent<Animator>().SetTrigger("reload");
    }

    // Update is called once per frame
    void Update()
    {
        timer += Time.deltaTime;
        timer2 += Time.deltaTime;
        if (Input.GetMouseButtonDown(0) && timer2 >= TBA && canShoot)
        {
            Shooting2D();
        }
        if(timer >= effectsDisplayTime)
        {
            gunLine.enabled = false;
        }
    }
}
