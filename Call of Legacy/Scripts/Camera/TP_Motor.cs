using UnityEngine;
using System.Collections;

public class TP_Motor : MonoBehaviour
{
    public static TP_Motor Instance;

    public float ForwardSpeed = 10f;
    public float BackwardSpeed = 2f;
    public float JumpSpeed = 8f;
    public float RotationSpeed = 1f;
    public float Gravity = 21f;
    public float TerminalVelocity = 20f;
    public float SlideThreshold = 0.8f;
    public float MaxControlableSlide = 0.9f;

    private Vector3 slideDirection;
    public bool IsSliding { get; set; }
    private float gravityForce = 8f;

    public Vector3 MoveVector { get; set; }
    public float Turn { get; set; }
    public float VerticalVelocity { get; set; }


    // Use this for initialization
    void Awake()
    {
        Instance = this;
        IsSliding = false;
    }

    // Update is called once per frame
    public void UpdateMotor()
    {
        if (MoveVector.x != 0 || MoveVector.z != 0)
            SnapAlignCharacterWithCamera();
        ProcessMotion();
    }

    public void ResetMotor()
    {
        VerticalVelocity = MoveVector.y;
        MoveVector = Vector3.zero;
        Turn = 0f;
    }

    void ProcessMotion()
    {
        // Transform MoveVector to World Space
        MoveVector = transform.TransformDirection(MoveVector);

        // Normalize MoveVector if Magnitude > 1
        if (MoveVector.magnitude > 1)
        {
            MoveVector = Vector3.Normalize(MoveVector);
        }

        ApplySlide();

        // Multiply MoveVector by MoveSpeed 
        MoveVector *= MoveSpeed();

        // Reapply VerticalVelocity
        MoveVector = new Vector3(MoveVector.x, VerticalVelocity, MoveVector.z);

        ApplyGravity();
        ApplyRotation();        

        // Move the Charcter in World Space
        TP_Controler.CharacterController.Move(MoveVector * Time.deltaTime);



    }

    void ApplyGravity()
    {
        if (MoveVector.y > -TerminalVelocity)
        {
            MoveVector = new Vector3(MoveVector.x, MoveVector.y - Gravity * Time.deltaTime, MoveVector.z);
        }

        //Reset Y axe 
        if (!IsSliding && TP_Controler.CharacterController.isGrounded && MoveVector.y < -gravityForce)
            MoveVector = new Vector3(MoveVector.x, -gravityForce, MoveVector.z);
    }

    void ApplyRotation()
    {
        //TP_Camera.Instance.RotateCamera(Turn * RotationSpeed);
        if (Turn != 0)
            SnapAlignCharacterWithCamera();

    }

    void ApplySlide()
    {
        if (!TP_Controler.CharacterController.isGrounded)
            return;

        slideDirection = Vector3.zero;

        RaycastHit hitInfo;

        if (Physics.Raycast(transform.position, Vector3.down, out hitInfo))
        {
            if (hitInfo.normal.y < SlideThreshold)
            {
                slideDirection = new Vector3(hitInfo.normal.x, -hitInfo.normal.y*3, hitInfo.normal.z);
                if (!IsSliding)
                {
                    TP_Animator.Instance.Slide();
                }
                IsSliding = true;
            }
            else
                IsSliding = false;

            if (hitInfo.normal.y < MaxControlableSlide)
                MoveVector = slideDirection;
            else
            {
                MoveVector += slideDirection;
            }
        }
        
    }


    public void Jump()
    {
        if (TP_Controler.CharacterController.isGrounded)
        {
            VerticalVelocity = JumpSpeed;
        }
    }

    void SnapAlignCharacterWithCamera()
    {        
        TP_Controler.Instance._transform.rotation = Quaternion.Euler(TP_Controler.Instance._transform.eulerAngles.x, Camera.main.transform.eulerAngles.y, TP_Controler.Instance._transform.eulerAngles.z);
    }

    float MoveSpeed()
    {
        float moveSpeed = 0f;

        switch (TP_Animator.Instance.MoveDirection)
        {
            case TP_Animator.Direction.Stationary:
                moveSpeed = 0;
                break;
            case TP_Animator.Direction.Forward:
                moveSpeed = ForwardSpeed;
                break;
            case TP_Animator.Direction.Backward:
                moveSpeed = BackwardSpeed;
                break;
            case TP_Animator.Direction.Left:
                moveSpeed = ForwardSpeed;
                break;
            case TP_Animator.Direction.Right:
                moveSpeed = ForwardSpeed;
                break;
            case TP_Animator.Direction.LeftForward:
                moveSpeed = ForwardSpeed;
                break;
            case TP_Animator.Direction.RightForward:
                moveSpeed = ForwardSpeed;
                break;
            case TP_Animator.Direction.LeftBackward:
                moveSpeed = BackwardSpeed;
                break;
            case TP_Animator.Direction.RightBackward:
                moveSpeed = BackwardSpeed;
                break;
        }

        if (IsSliding)
            moveSpeed = ForwardSpeed;

        return moveSpeed;
    }

}
