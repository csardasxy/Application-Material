using UnityEngine;
using System.Collections;

public class TP_Controler : MonoBehaviour {
    public static CharacterController CharacterController;
    public static TP_Controler Instance;


    public Transform _transform { get; set; }
    


	// Use this for initialization
	void Awake () {
        CharacterController = GetComponent("CharacterController") as CharacterController;
        Instance = this;
        //TP_Camera.AttachCamera();
        _transform = transform;

        
	}

    
	
	// Update is called once per frame
	void Update () {
        if (Camera.main == null)
            return;

        TP_Motor.Instance.ResetMotor();

        if (!TP_Animator.Instance.IsDead &&
            TP_Animator.Instance.State != TP_Animator.CharacterState.Using &&
            TP_Animator.Instance.State != TP_Animator.CharacterState.Landing)
        {
            GetLocomotionInput();
            HandleActionInput();
        }
        
        
        TP_Motor.Instance.UpdateMotor();

        
	}

    void GetLocomotionInput()
    {
        var deadZone = 0.1f;
        if(TP_Animator.Instance.State == TP_Animator.CharacterState.Defending) {
            return;
        }
        if (Input.GetAxis("Vertical") > deadZone || Input.GetAxis("Vertical") < -deadZone)
        {
            TP_Motor.Instance.MoveVector += new Vector3(0, 0, Input.GetAxis("Vertical"));
        }

        if (Input.GetAxis("Horizontal") > deadZone || Input.GetAxis("Horizontal") < -deadZone)
        {
            TP_Motor.Instance.MoveVector += new Vector3(Input.GetAxis("Horizontal"),0,0);
        }
        /*
        if (Input.GetAxis("Turn") > deadZone || Input.GetAxis("Turn") < -deadZone)
        {
            TP_Motor.Instance.Turn += Input.GetAxis("Turn");
        }
        */
        TP_Animator.Instance.DetermineCurrentMoveDirection();
        
    }

    public float AttackRange = 5f;
    public float AttackRate = 0.5f;
    public float time1 = 0.3f;
    public int AttackTimes = 0;
    float timer;
    bool Attack1 = true;
    bool Attack2 = true;
    bool Attack3 = true;
    public float Damage = 30f;
    public ParticleSystem[] particle;

    void HandleActionInput()
    {
        if (TP_Animator.Instance.State != TP_Animator.CharacterState.Defending) {
            if (Input.GetButtonDown("Jump")) {
                Jump();
                TP_Motor.Instance.Jump();
            }
            if (Input.GetKeyDown(KeyCode.E)) {
                Build();
            }

            //timer = timer + Time.deltaTime;
            //if (timer > (AttackRate + 0.5f)) {
            //    AttackTimes = 0;
            //}
            if (Input.GetButtonDown("Fire1") && AttackTimes == 2 && Time.time - timer <= 0.4f && TP_Animator.Instance.State != TP_Animator.CharacterState.Defending) {
                timer = Time.time;
                StartCoroutine(attack2());
            }
            if (Input.GetButtonDown("Fire1") && AttackTimes == 1 && Time.time - timer <= 0.4f && TP_Animator.Instance.State != TP_Animator.CharacterState.Defending) {
                timer = Time.time;
                StartCoroutine(attack1());
            }
            if (Input.GetButtonDown("Fire1") && Time.time - timer > 0.5f && TP_Animator.Instance.State != TP_Animator.CharacterState.Defending) {//attack
                timer = Time.time;
                StartCoroutine(attack());
            }
        }
        if (Input.GetKeyUp("f")) {
            //defend
            Defend(false);
        }

        if (Input.GetKey("f")) {
            //defend
            Defend(true);

        }
    }

    void Use()
    {
        TP_Animator.Instance.Use();
    }

    void Build() {
        GameObject.FindGameObjectWithTag("MainCamera").GetComponent<MonumentSystem>().Build(0);
    }

    void Jump() {
        TP_Animator.Instance.Jump();
    }

    void Defend(bool defend) {
        TP_Animator.Instance.Defend(defend);
    }

    IEnumerator attack() {

        Damage = GameObject.FindGameObjectWithTag("Player").GetComponent<person>().ATK * 0.3f;

        AttackTimes = 1;
        TP_Animator.Instance.Attack(1);

        Ray ray = new Ray(transform.position + new Vector3(0, 1, 0), transform.forward);
        RaycastHit hit;//hit the Enemy

        Vector3 targetPosition = transform.position + new Vector3(0, 0, AttackRange);

        while (Attack1) {

            if (TP_Animator.Instance.GetComponent<Animator>().GetCurrentAnimatorStateInfo(0).IsName("Attack1")) {
                if (Physics.Raycast(ray, out hit, AttackRange, LayerMask.GetMask("Monster"))) {

                    EnemyHealth enemy;
                    enemy = hit.collider.GetComponent<EnemyHealth>();
                    if (enemy != null) {

                        enemy.GetDamaged(Damage);

                    }

                }
                particle[2].Play();
                Attack1 = false;

            }
            yield return null;
        }
        Attack1 = true;

    }
    IEnumerator attack1() {

        AttackTimes = 2;

        TP_Animator.Instance.Attack(2);

        Ray ray = new Ray(transform.position + new Vector3(0, 1, 0), transform.forward);
        RaycastHit hit;//hit the Enemy

        Vector3 targetPosition = transform.position + new Vector3(0, 0, AttackRange);



        while (Attack2) {

            if (TP_Animator.Instance.GetComponent<Animator>().GetCurrentAnimatorStateInfo(0).IsName("Attack2")) {
                if (Physics.Raycast(ray, out hit, AttackRange, LayerMask.GetMask("Monster"))) {

                    EnemyHealth enemy;
                    enemy = hit.collider.GetComponent<EnemyHealth>();
                    if (enemy != null) {

                        enemy.GetDamaged(Damage);

                    }

                }
                particle[0].Play();
                Attack2 = false;

            }
            yield return null;
        }

        Attack2 = true;
    }
    IEnumerator attack2() {

        AttackTimes = 0;

        TP_Animator.Instance.Attack(3);

        Ray ray = new Ray(transform.position + new Vector3(0, 1, 0), transform.forward);
        RaycastHit hit;//hit the Enemy

        Vector3 targetPosition = transform.position + new Vector3(0, 0, AttackRange);

        while (Attack3) {

            if (TP_Animator.Instance.GetComponent<Animator>().GetCurrentAnimatorStateInfo(0).IsName("Attack3")) {

                if (Physics.Raycast(ray, out hit, AttackRange, LayerMask.GetMask("Monster"))) {

                    EnemyHealth enemy;
                    enemy = hit.collider.GetComponent<EnemyHealth>();
                    if (enemy != null) {

                        enemy.GetDamaged(Damage);

                    }


                }
                particle[1].Play();
                Attack3 = false;

            }
            yield return null;
        }
        Attack3 = true;
    }
}
