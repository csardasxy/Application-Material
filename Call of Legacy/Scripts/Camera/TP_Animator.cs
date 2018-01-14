using UnityEngine;
using System.Collections;

public class TP_Animator : MonoBehaviour 
{

    public int canAttack = 1;

    public enum Direction
    {
        Stationary, Forward, Backward, Left, Right,
        LeftForward, RightForward, LeftBackward, RightBackward
    }

    public enum CharacterState 
    {
        idle, Running, WalkingBackwards, WalkingBackwardLeft, WalkingBackwardRigh, 
        RunningLeft, RunningRight, RunningLeftForward, RunningRightForward, Jumping, Falling,
        Landing, Sliding, Using, Dead, ActionLocked, Attacking,Defending
    }

    public static TP_Animator Instance;

    private CharacterState lastState;

    private Vector3 initialPosition = Vector3.zero;
    private Quaternion initialRotation = Quaternion.identity;

    public Direction MoveDirection { get; set; }
    public CharacterState State { get; set; }
    public bool IsDead { get; set; }

    public AudioSource step, atk1, atk2, atk3;


    void Awake()
    {
        Instance = this;
        
    }

    void Start()
    {
        initialPosition = TP_Controler.Instance._transform.position;
        initialRotation = TP_Controler.Instance._transform.rotation;
    }
    	
    void FixedUpdate()
    {
        if (gameObject.GetComponent<Animator>().GetBool("move"))
            step.Play();
        else
            step.Stop();
    }
	void Update () 
    {
        DetermineCurrentState();
        Debug.Log(State);
        ProcessCurrentState();
	}

    public void DetermineCurrentMoveDirection()
    {
        bool forward = false;
        bool backward = false;
        bool left = false;
        bool right = false;

        if (TP_Motor.Instance.MoveVector.z > 0)
            forward = true;
        if (TP_Motor.Instance.MoveVector.z < 0)
            backward = true;
        if (TP_Motor.Instance.MoveVector.x > 0)
            right = true;
        if (TP_Motor.Instance.MoveVector.x < 0)
            left = true;

        if (forward)
        {
            if (left)
                MoveDirection = Direction.LeftForward;
            else if (right)
                MoveDirection = Direction.RightForward;
            else
            {
                MoveDirection = Direction.Forward;
            }
                
        }
        else if (backward)
        {
            if (left)
                MoveDirection = Direction.LeftBackward;
            else if (right)
                MoveDirection = Direction.RightBackward;
            else
                MoveDirection = Direction.Backward;
        }
        else if (left)
            MoveDirection = Direction.Left;
        else if (right)
            MoveDirection = Direction.Right;
        else
            MoveDirection = Direction.Stationary;

    }

    void DetermineCurrentState()
    {
        if (State == CharacterState.Dead) {
            return;
        }


        if (!TP_Controler.CharacterController.isGrounded)
        {
            if (State != CharacterState.Falling  &&   
                State != CharacterState.Jumping  &&
                State != CharacterState.Attacking &&
                State != CharacterState.Landing)
            {
                // We should be falling
                Fall();
            }
        }

        if (State != CharacterState.Falling &&
            State != CharacterState.Jumping &&
            State != CharacterState.Landing &&
            State != CharacterState.Using &&
            State != CharacterState.Attacking &&
            State != CharacterState.Defending &&
            State != CharacterState.Sliding)
        {
            switch (MoveDirection)
            {
                case Direction.Stationary:
                    State = CharacterState.idle;
                    break;
                case Direction.Forward:
                    State = CharacterState.Running;
                    break;
                case Direction.Backward:
                    State = CharacterState.WalkingBackwards;
                    break;
                case Direction.Left:
                    State = CharacterState.RunningLeft;
                    break;
                case Direction.Right:
                    State = CharacterState.RunningRight;
                    break;
                case Direction.LeftForward:
                    State = CharacterState.RunningLeftForward;
                    break;
                case Direction.RightForward:
                    State = CharacterState.RunningRightForward;
                    break;
                case Direction.LeftBackward:
                    State = CharacterState.WalkingBackwardLeft;
                    break;
                case Direction.RightBackward:
                    State = CharacterState.WalkingBackwardRigh;
                    break;
            }
        }
    }

    void ProcessCurrentState()
    {
        switch (State)
        {
            case CharacterState.idle:
                idle();
                break;
            case CharacterState.Running:
                Running();
                break;
            case CharacterState.WalkingBackwards:
                WalkingBackwards();
                break;
            case CharacterState.RunningLeft:
                RunningLeft();
                break;
            case CharacterState.RunningRight:
                RuningRight();
                break;
            case CharacterState.Jumping:
                Jumping();
                break;
            case CharacterState.Falling:
                Falling();
                break;
            case CharacterState.Landing:
                Landing();
                break;
            case CharacterState.Attacking:
                Attacking();
                break;
                /*
            case CharacterState.Sliding:
                Sliding();
                break;
                */
            case CharacterState.Using:
                Using();
                break;
            case CharacterState.Dead:
                Dead();
                break;
            case CharacterState.ActionLocked:
                ActionLocked();
                break;
        }
    }



    #region Charachter State Methods

    void idle()
    {
        gameObject.GetComponent<Animator>().SetBool("move", false);

    }

    void Running()
    {
        gameObject.GetComponent<Animator>().SetBool("move", true);
        //animation.CrossFade("Running");
    }

    void WalkingBackwards()
    {
        gameObject.GetComponent<Animator>().SetBool("move", true);
        
        //animation.CrossFade("WalkingBackwards");
    }

    void WalkingBackwardLeft()
    {
        gameObject.GetComponent<Animator>().SetBool("move", true);
        //animation.CrossFade("WalkingBackwardLeft");
    }

    void WalkingBackwardRight()
    {
        gameObject.GetComponent<Animator>().SetBool("move", true);
        //animation.CrossFade("WalkingBackwardRight");
    }

    void RunningLeft()
    {
        gameObject.GetComponent<Animator>().SetBool("move", true);
        //animation.CrossFade("RunningLeft");
    }

    void RuningRight()
    {
        gameObject.GetComponent<Animator>().SetBool("move", true);
        //animation.CrossFade("RunningRight");
    }

    void RunningLeftForward()
    {
        gameObject.GetComponent<Animator>().SetBool("move", true);
        //animation.CrossFade("RunningLeftForward");
    }

    void RunningRightForward()
    {
        gameObject.GetComponent<Animator>().SetBool("move", true);
        //animation.CrossFade("RunningRightForward");
    }

    void Jumping()
    {
        if (TP_Controler.CharacterController.isGrounded)
        {
            if (lastState == CharacterState.Running)
            {
                State = CharacterState.Running;
                // animation.CrossFade("RunLand");
            }
            else
            {
                State = CharacterState.idle;
                // animation.CrossFade("JumpLand");
            }
        }
        else
        {
            State = CharacterState.Falling;
            // Help determine if we fell to far
        }
    }

    void Falling()
    {
        if (TP_Controler.CharacterController.isGrounded)
        {
            if (lastState == CharacterState.Running)
            {
                // animation.CrossFade("RunLand");
            }
            else
            {
                // animation.CrossFade("JumpLand");
            }
            State = CharacterState.Landing;
        }
    }

    void Landing()
    {
        if (lastState == CharacterState.Running)
        {
            State = CharacterState.Running;
        }
        else
        {
            State = CharacterState.idle;
        }
    }

    void Sliding()
    {
        if (!TP_Motor.Instance.IsSliding)
        {
            State = CharacterState.idle;
             GetComponent<Animation>().CrossFade("idle");
        }
    }

    void Attacking() {
        if (TP_Controler.CharacterController.isGrounded) {
            if (lastState == CharacterState.Running) {
                State = CharacterState.Running;
                // animation.CrossFade("RunLand");
            } else {
                State = CharacterState.idle;
                // animation.CrossFade("JumpLand");
            }
        } else {
            State = CharacterState.Falling;
            // Help determine if we fell to far
        }
    }

    void Using()
    {/*
        if (!GetComponent<Animation>().isPlaying)
        {
            
            //animation.CrossFade("idle");
        }*/
        State = CharacterState.idle;
    }

    void Dead()
    {
        IsDead = true;
        State = CharacterState.Dead;
    }

    void ActionLocked()
    {

    }

    #endregion


    #region Start Action Method

    public void Use()
    {
        State = CharacterState.Using;
        //animation.CrossFade("Using");
    }

    public void Jump()
    {
        if (!TP_Controler.CharacterController.isGrounded || IsDead || State == CharacterState.Jumping)
            return;

        lastState = State;
        State = CharacterState.Jumping;
        // animation.CrossFade("Jumping");
    }

    public void Attack(int phase) {
        if (IsDead || canAttack <= 0)
            return;
        
        lastState = State;
        State = CharacterState.Attacking;
        switch (phase) {
            case 1:
                GetComponent<Animator>().SetTrigger("Attack1");
                atk1.Play();
                break;
            case 2:
                GetComponent<Animator>().SetTrigger("Attack2");
                atk2.Play();
                break;
            case 3:
                GetComponent<Animator>().SetTrigger("Attack3");
                atk3.Play();
                break;
        }
    }

    public void Fall()
    {
        if (IsDead)
            return;

        lastState = State;
        State = CharacterState.Falling;
        // animation.CrossFade("Falling");
    }

    public void Slide()
    {
        State = CharacterState.idle;
        // animation.CrossFade("Sliding");
    }

    public void Defend(bool defend) {
        if (IsDead)
            return;

        lastState = State;
        if (defend) {
            State = CharacterState.Defending;
            GetComponent<Animator>().SetBool("Defend", true);
        } else {
            State = CharacterState.idle;
            GetComponent<Animator>().SetBool("Defend", false);
        }
    }

    public void Die()
    {
        // Initialize everything we need to die
        Dead();
        GetComponent<Animator>().SetTrigger("Died");  
    }

    public void Reset()
    {
        // Reset player to play again
        State = CharacterState.idle;
        IsDead = false;
    }
    #endregion
} 
