using UnityEngine;
using System.Collections;

/// <summary>
/// This controls enemies's health (get damaged, die)
/// </summary>

public class EnemyHealth : MonoBehaviour {
	public float StartingHealth=100f;
	public float currentHealth;
	public float SinkingSpeed=1.5f;
	public bool isDied;
	public float exp=50f;
	public PlayerHealth player;
	public TP_Controler player1;
	public lvlUp level;
	public ParticleSystem[] part;
    public GameObject dropdown;

    public AudioSource hitted;

	bool hurt=false;
	LayerMask layer;
	private Vector3 birthPlace;
	float timer=0f;
	bool isSinking=false;
	Animation anim;
	// Use this for initialization
	void Awake(){
		birthPlace = transform.position;
	}
	void Start () {

        hitted = GameObject.FindGameObjectWithTag("Hitted").GetComponent<AudioSource>();

		player1 = GameObject.Find ("Character").GetComponent<TP_Controler> ();
		player = GameObject.Find ("Character").GetComponent<PlayerHealth>();
		level = GameObject.Find ("Character").GetComponent<lvlUp>();
        dropdown = GameObject.Find("DropDown");

		layer = LayerMask.GetMask ("Character");
		isDied = false;
		currentHealth = StartingHealth;
		anim = GetComponent<Animation> ();
		anim.Play ("idle break 2");
		anim.PlayQueued ("walk");
	}
	
	// Update is called once per frame
	void Update () {
		
		timer = timer + Time.deltaTime;
		if (isSinking && timer>2f) {
			transform.Translate ((-1) * transform.up * SinkingSpeed * Time.deltaTime);//if monster died,then sink
		}
		if (Vector3.Distance( transform.position , birthPlace)<1f && currentHealth < 20 && isDied==false) {
			GetComponent<Rigidbody> ().drag = Mathf.Infinity;
			hurt = true;
			Vector3 direction = player.transform.position-transform.position;
			direction.y = 0;
			Quaternion target = Quaternion.LookRotation (direction);
			transform.rotation=Quaternion.RotateTowards(transform.rotation,target,Time.deltaTime*100f);
			anim.Stop ();
			anim.PlayQueued ("idle break 1");
			return;

		}
		if (currentHealth < 20 && isDied==false && !hurt) {
			
			anim.Play ("falling");
			transform.parent = null;
			GetComponent<EnemyMoving> ().enabled = false;//close moving togethor and run
			Vector3 direction = birthPlace-transform.position;
			direction.y = 0;
			Quaternion target = Quaternion.LookRotation (direction);
			transform.rotation=Quaternion.RotateTowards(transform.rotation,target,Time.deltaTime*100f);
			transform.Translate (-direction.normalized*Time.deltaTime*5f);
		}

	}               
	public void GetDamaged(float damage){
		if (isDied) {
			return;
		}

		if(Physics.Raycast(transform.position,transform.forward,5f,layer)){
			anim.Play ("hit front");
            hitted.PlayOneShot(hitted.clip);
		}
			else{
				anim.Play("hit back");
            hitted.PlayOneShot(hitted.clip);
        }
		anim.PlayQueued("walk");
		currentHealth = currentHealth - damage;
		if (player1.AttackTimes == 2) {
			part [1].Play ();
		} else {
			part [0].Play ();
		}
		if (currentHealth <= 0) {
			dead ();
		}
	}
	void dead(){
		timer = 0f;
		anim.Play ("die");
		isDied = true;
		level.AddExp (exp);
		GetComponent<CapsuleCollider> ().isTrigger = true;
		GetComponent<Rigidbody> ().isKinematic = true;
		isSinking = true;
		Destroy (gameObject, 3f);

        Instantiate(dropdown, transform.position, transform.rotation);
	}
}                
