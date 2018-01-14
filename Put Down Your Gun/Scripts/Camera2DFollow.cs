using System;
using UnityEngine;

/// <summary>
/// This script can make the camera follow the character with an offset and delay.
/// </summary>

namespace UnityStandardAssets._2D
{
    public class Camera2DFollow : MonoBehaviour
    {
        public Transform target;
        public float zoomSpeed;
        public float gateSpeed;
        public float damping = 1;
        public float lookAheadFactor = 3;
        public float lookAheadReturnSpeed = 0.5f;
        public float lookAheadMoveThreshold = 0.1f;

        private float m_OffsetZ;
        private Vector3 m_LastTargetPosition;
        private Vector3 m_CurrentVelocity;
        private Vector3 m_LookAheadPos;

        // Use this for initialization
        private void Start()
        {
            m_LastTargetPosition = target.position + new Vector3(0,8.46f,0);
            m_OffsetZ = (transform.position - target.position + new Vector3(0,8.46f,0)).z;
            transform.parent = null;
        }


        // Update is called once per frame
        private void Update()
        {
            //only update lookahead pos if accelerating or changed direction.
            float xMoveDelta = (target.position + new Vector3(0,8.46f,0) - m_LastTargetPosition).x;

            bool updateLookAheadTarget = Mathf.Abs(xMoveDelta) > lookAheadMoveThreshold;

            //auto follows the character.
            if (updateLookAheadTarget)
            {
                m_LookAheadPos = lookAheadFactor * Vector3.right * Mathf.Sign(xMoveDelta);
            }
            else
            {
                m_LookAheadPos = Vector3.MoveTowards(m_LookAheadPos, Vector3.zero, Time.deltaTime * lookAheadReturnSpeed);
            }

            Vector3 aheadTargetPos = target.position + new Vector3(0,8.46f,0) + m_LookAheadPos + Vector3.forward * m_OffsetZ;
            Vector3 newPos = Vector3.SmoothDamp(transform.position, aheadTargetPos, ref m_CurrentVelocity, damping);

            transform.position = newPos;

            m_LastTargetPosition = target.position + new Vector3(0,8.46f,0);
            
            //auto zoom as the character's speed changes.
            if (target.gameObject.GetComponent<Rigidbody2D>().velocity.SqrMagnitude() >= gateSpeed && this.gameObject.GetComponent<Camera>().orthographicSize < 10f)
            {
                this.gameObject.GetComponent<Camera>().orthographicSize += zoomSpeed;
            }
            if(target.gameObject.GetComponent<Rigidbody2D>().velocity.SqrMagnitude() <= gateSpeed && this.gameObject.GetComponent<Camera>().orthographicSize > 5f)
            {
                this.gameObject.GetComponent<Camera>().orthographicSize -= zoomSpeed;
            }
        }
    }
}
