using UnityEngine;
using System.Collections;
using UnityStandardAssets.CrossPlatformInput;

/// <summary>
/// This script contains basic control methods of the character.
/// </summary>

public class Character_controller : MonoBehaviour {

    public bool isFaceRight = true;
    public float speed;
    [SerializeField]private float runScale = 1.01f;
    Animator animator;
    [SerializeField]private LayerMask ground;
    [SerializeField]private float checkRedius;
    private bool isOnGround;
    [SerializeField]private Transform groundCheck;
    [SerializeField]private GameObject legs;
    private float timer;

	// Use this for initialization
	void Start () {
        animator = this.gameObject.GetComponent<Animator>();
        groundCheck = transform.Find("GroundCheck");
        legs = GameObject.Find("legs");
        Debug.Log(groundCheck.position);
	}

    void FixedUpdate()
    {
        //Judge if the character is standing on the ground, in order to select the responding animation to play.
        isOnGround = false;
        Collider2D[] colliders = Physics2D.OverlapCircleAll(groundCheck.position, checkRedius, ground);
        for (int i = 0; i < colliders.Length; i++)
        {
            if (colliders[i].gameObject != legs)
            {
                isOnGround = true;
            }
        }

        //Get mouse's position on screen to flip character's sprite.
        Vector3 mousePosi = Camera.main.ScreenToWorldPoint(Input.mousePosition);
        float deltaX = mousePosi.x - this.transform.position.x;
        if (deltaX > 0 && !isFaceRight || deltaX < 0 && isFaceRight)
            Flip();
        speed = CrossPlatformInputManager.GetAxis("Horizontal");

        //When the LeftShift key is pressed, the character will run in a higher speed and the running animation will play.
        if(Input.GetKey(KeyCode.LeftShift))
        {
            speed *= runScale;
        }
        if(!isOnGround)
            Debug.Log("FLY");
        Move();
    }

    public void Move()
    {
        gameObject.GetComponent<Rigidbody2D>().velocity = new Vector2(speed*7, gameObject.GetComponent<Rigidbody2D>().velocity.y);
        if(isOnGround)
        {
            //Animator's playing speed is related to the character's realtime moving speed.
            animator.SetBool("falling", false);
            float spd = Mathf.Abs(speed);
            if ((speed < 0 && isFaceRight) || (speed > 0 && !isFaceRight))
            {
                animator.SetFloat("speed", -spd+0.01f);
            }
            else
                animator.SetFloat("speed", spd-0.01f);
        }
        else
        {
            //The "falling" clip can be played no more than 3 seconds.
            animator.SetBool("falling", true);
            timer += Time.deltaTime;
            if(timer == 3)
            {
                isOnGround = true;
                timer = 0;
            }
        }

    }

    //Flip character's sprite
    private void Flip()
    {
        isFaceRight = !isFaceRight;
        Vector3 scale = this.transform.localScale;
        scale.x *= -1;
        GameObject[] arms = this.gameObject.GetComponent<Aim_Shoot>().arms;
        for (int i = 0; i < arms.Length; i++)
        {
            Quaternion rotation = new Quaternion(0,0,0,0);
            arms[i].transform.rotation = rotation;
        }
        this.transform.localScale = scale;
    }
}
