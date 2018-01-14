using UnityEngine;
using System.Collections;

/// <summary>
/// Hero's moving animation and keyboard control.
/// </summary>

public class PlayerMoving : MonoBehaviour {
	public float AttackRange = 0.5f;
	public Camera mCamera;
	public float RayRange=100f;//mouse RayRange
	public float speed=10f;//character speed
	public bool defended=false;
	public float Damage = 30f;
	public float DamageOnBoss = 10f;
	public float AttackRate=0.5f;
	public  ParticleSystem[] particle;
	public float time1=0.3f;
	public int AttackTimes=0;

	private CharacterController controller;
	private CharacterMotor motor;
	bool Attack1=true;
	bool Attack2=true;
	bool Attack3=true;
    public bool canAttack = true;

	int layerPlayer;

	float timer;
	int layer;
	int layerBoss;
	Animator anim;
	int layerMask ;
	// Use this for initialization
	void Start () {
		controller = GetComponent<CharacterController> ();
		motor = GetComponent<CharacterMotor> ();
		layerPlayer = LayerMask.GetMask ("Player");
		timer = 0f;
		anim = GetComponent<Animator> ();
		layerMask = LayerMask.GetMask ("Floor");
		layer = LayerMask.GetMask ("Monster");
		layerBoss = LayerMask.GetMask ("Boss");
	}

	// Update is called once per frame
	void Update () {

		if (!motor.canControl) {
			motor.canControl = true;
		}

		timer = timer + Time.deltaTime;
		if (timer > (AttackRate-0.1)) {
			AttackTimes = 0;
		}
		if (GetComponent<Rigidbody>().velocity==Vector3.zero) {
			anim.SetBool ("move", false);
		}//if stop play Idle
		float x=Input.GetAxis("Horizontal");
		float y = Input.GetAxis ("Vertical");



		if (Input.GetButtonDown ("Fire1") && AttackTimes == 2 && timer<=time1 && defended==false) {
			StartCoroutine( attack2 ());

		}
		if (Input.GetButtonDown ("Fire1") && AttackTimes == 1 &&  timer<=time1 && defended==false) {
			StartCoroutine( attack1 ());
		}
		if(Input.GetButtonDown("Fire1") && timer>=AttackRate && defended==false && canAttack){//attack
			StartCoroutine( attack ());
		}
		if(Input.GetKeyUp(KeyCode.B)){
			//defend
			defended=false;
			anim.SetBool ("Defend", false);
		}

		if(Input.GetKey(KeyCode.B)){
			//defend
			defended=true;
			anim.SetBool ("Defend", true);

		}
		if ( y >0) {
			

			particle [3].Play ();
		}
		if (y < 0) {
			particle [4].Play ();
		}

		if (x == 0 && y == 0) {
			particle [4].Stop ();
			particle [3].Stop ();
			GetComponent<Rigidbody> ().velocity = Vector3.zero;
		}
		if (defended) {
			motor.canControl = false;
			moveTowards ();
			return;
		}
		move (x,y);//move character
		moveTowards ();
	}
	void FixedUpdate(){
		
	}

	void moveTowards(){
		RaycastHit floor;

		Ray position = mCamera.ScreenPointToRay (Input.mousePosition);
		if (Physics.Raycast (position, out floor, RayRange, layerMask)) {
//			Debug.Log ("a");
			Vector3 direction = (floor.point - transform.position).normalized;
		
			direction.y = 0;
			Quaternion target = Quaternion.LookRotation (direction);
			transform.rotation = target;


		}
	}
	void move(float x,float y){
		RaycastHit floor;

		Ray position = mCamera.ScreenPointToRay (Input.mousePosition);
		if (Physics.Raycast (position, out floor, RayRange, layerMask)) {
			Vector3 direction1=new Vector3(x,0,y); 
			Vector3 direction = (floor.point - transform.position).normalized;
			direction.y = 0;
			Quaternion target = Quaternion.LookRotation (direction);
			transform.rotation = target;
			float directionLength = direction1.magnitude;
			direction1=direction1/directionLength;
			directionLength = Mathf.Min(1, directionLength);
			directionLength = directionLength * directionLength;
			direction1 = direction1 * directionLength;

			motor.inputMoveDirection = transform.TransformDirection(direction1);
			motor.inputJump = Input.GetButton ("Jump");
//			motor.movement.maxForwardSpeed = speed;
//			motor.movement.maxBackwardsSpeed = speed;
//			motor.movement.maxSidewaysSpeed = speed;

			if (x != 0 || y != 0) {
				
				anim.SetBool ("move", true);
			}
		}
	}

	IEnumerator attack(){
		
		AttackTimes = 1;
		timer = 0f;
		anim.SetTrigger ("Attack1");

		Ray ray = new Ray (transform.position, transform.forward);
		RaycastHit hit;//hit the Enemy

		Vector3 targetPosition = transform.position + new Vector3 (0, 0, AttackRange);

		while (Attack1) {
			
			if (anim.GetCurrentAnimatorStateInfo (0).IsName ("Attack1")) {
				if (Physics.CapsuleCast(transform.position,transform.position,0.5f,transform.forward,out hit,layer) ){

					EnemyHealth enemy;
					enemy = hit.collider.GetComponent<EnemyHealth> ();
					if (enemy == null) {
						
					}
					if (enemy != null) {

						enemy.GetDamaged (Damage);

					}

				}
				if (Physics.CapsuleCast(transform.position,transform.position,0.5f,transform.forward,out hit,layerBoss)){
					
					BossHealth enemy;
					enemy = hit.collider.GetComponent<BossHealth> ();
					if (enemy == null) {

					}
					if (enemy != null) {

						enemy.GetDamaged (DamageOnBoss);

					}

				}
				particle [2].Play ();
				Attack1 = false;

			}
			yield return null;
		}
		Attack1 = true;

	}
	IEnumerator attack1(){
		
		AttackTimes = 2;

		anim.SetTrigger ("Attack2");

		Ray ray = new Ray (transform.position+new Vector3(0,1,0), transform.forward);
		RaycastHit hit;//hit the Enemy

		Vector3 targetPosition = transform.position + new Vector3 (0, 0, AttackRange);



		while (Attack2) {
			
			if (anim.GetCurrentAnimatorStateInfo (0).IsName ("Attack2")) {
				if (Physics.CapsuleCast(transform.position,transform.position,0.5f,transform.forward,out hit,layerBoss) ){

					BossHealth enemy;
					enemy = hit.collider.GetComponent<BossHealth> ();
					if (enemy == null) {

					}
					if (enemy != null) {

						enemy.GetDamaged (DamageOnBoss);

					}

				}
				if (Physics.CapsuleCast(transform.position,transform.position,0.5f,transform.forward,out hit,layer) ){

					EnemyHealth enemy;
					enemy = hit.collider.GetComponent<EnemyHealth> ();
					if (enemy != null) {

						enemy.GetDamaged (Damage);

					}

				}
				particle [0].Play ();
				Attack2 = false;

			}
			yield return null;
		}

		Attack2 = true;
	}
	IEnumerator attack2(){

		AttackTimes = 0;

		anim.SetTrigger ("Attack3");

		Ray ray = new Ray (transform.position+new Vector3(0,1,0), transform.forward);
		RaycastHit hit;//hit the Enemy

		Vector3 targetPosition = transform.position + new Vector3 (0, 0, AttackRange);

		while (Attack3) {

			if (anim.GetCurrentAnimatorStateInfo (0).IsName ("Attack3")) {
				
				if (Physics.CapsuleCast(transform.position,transform.position,0.5f,transform.forward,out hit,layer)  ){

					EnemyHealth enemy;
					enemy = hit.collider.GetComponent<EnemyHealth> ();
					if (enemy != null) {

						enemy.GetDamaged (Damage);

					}


				}
				if (Physics.CapsuleCast(transform.position,transform.position,0.5f,transform.forward,out hit,layerBoss) ){

					BossHealth enemy;
					enemy = hit.collider.GetComponent<BossHealth> ();
					if (enemy == null) {

					}
					if (enemy != null) {

						enemy.GetDamaged (DamageOnBoss);

					}

				}
				particle [1].Play ();
				Attack3 = false;

			}
			yield return null;
		}
		Attack3 = true;

	}
}
