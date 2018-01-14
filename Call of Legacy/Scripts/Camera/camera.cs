using UnityEngine;
using System.Collections;

[AddComponentMenu("Camera-Control/Mouse Look")]
public class camera : MonoBehaviour {

		public enum RotationAxes { MouseXAndY = 0, MouseX = 1, MouseY = 2 }

		public RotationAxes axes = RotationAxes.MouseXAndY;

		public float sensitivityX = 0.0001F;

		public float sensitivityY = 0.0001F;



		public float minimumX = -360F;

		public float maximumX = 360F;



		public float minimumY = -85F;

		public float maximumY = 4F;



		public float rotationY = 0F;



		public GameObject target;
	public Transform targetPosition;


		public float theDistance = -10f;

		public float MaxDistance = -10f;

		public float ScrollKeySpeed = 100.0f;

		void Update()
		{
			//这里的target要改成你主角的名字
		    targetPosition = target.transform;

			// 滚轮设置 相机与人物的距离.

			if (Input.GetAxis("Mouse ScrollWheel") != 0)
			{

				theDistance = theDistance + Input.GetAxis("Mouse ScrollWheel") * Time.deltaTime * ScrollKeySpeed;

			}

			// 鼠标中间滚动得到的值是不确定的,不会正好就是0,或 -10,当大于0时就设距离为0,小于MaxDistance就设置为MaxDistance

			if (theDistance > 0)

				theDistance = 0;

			if (theDistance < MaxDistance)

				theDistance = MaxDistance;
			//按下鼠标右键
			if (Input.GetMouseButton(1))
			{
                Cursor.visible = false;
				transform.position = target.transform.position;

				if (axes == RotationAxes.MouseXAndY)
				{

					float rotationX = transform.localEulerAngles.y + Input.GetAxis("Mouse X") * sensitivityX;



					rotationY += Input.GetAxis("Mouse Y") * sensitivityY;

					rotationY = Mathf.Clamp(rotationY, minimumY, maximumY);

					transform.localEulerAngles = new Vector3(-rotationY, rotationX, 0);

				}

				else if (axes == RotationAxes.MouseX)
				{

					transform.Rotate(0, Input.GetAxis("Mouse X") * sensitivityX, 0);

				}

				else
				{

					rotationY += Input.GetAxis("Mouse Y") * sensitivityY;

					rotationY = Mathf.Clamp(rotationY, minimumY, maximumY);

					transform.localEulerAngles = new Vector3(-rotationY, transform.localEulerAngles.y, 0);

				}

				SetDistance();

			}

			else
			{
                Cursor.visible = true;
                transform.position = target.transform.position;

				SetDistance();

			}

		//这里是计算射线的方向，从主角发射方向是射线机方向
		Vector3 aim = targetPosition.position;
		//得到方向
		Vector3 ve = (targetPosition.position - transform.position).normalized;
		float an = transform.eulerAngles.y;
		aim -= an * ve ;
		//在场景视图中可以看到这条射线
		Debug.DrawLine(targetPosition.position,aim,Color.red);
		//主角朝着这个方向发射射线
		RaycastHit hit;
		if(Physics.Linecast(targetPosition.position,aim,out hit))
		{
			string name =  hit.collider.gameObject.tag;
			if(name != "Player" && name != "MainCamera" && name != "terrain" && name != "Monster")
			{
                //当碰撞的不是摄像机也不是地形 那么直接移动摄像机的坐标
                if (Vector3.Distance(targetPosition.position, hit.point) < -theDistance) {
                    transform.position = hit.point;
                }

            }
		}


		}



		void Start()
		{

			if (GetComponent<Rigidbody>())
			{

				GetComponent<Rigidbody>().freezeRotation = true;

				transform.position = target.transform.position;

			}

		}



		//设置相机与人物之间的距离

		void SetDistance()
		{

			transform.Translate(Vector3.forward * theDistance);

		}

}
