using UnityEngine;
using System.Collections;

/// <summary>
/// This script controls the scroll action of the background iamge.
/// And the scroller's direction is based on the target(character)'s moving vector.
/// </summary>

public class BackGroundScroll : MonoBehaviour {
    public Transform target;
    public float scale = 0.9f;
    Vector3 local;
    Vector3 targetLocal;
    // Use this for initialization
    void Start () {
        local = new Vector3(this.transform.position.x, this.transform.position.y, this.transform.position.z);
        targetLocal = new Vector3(target.position.x, target.position.y, target.position.z);
	}
	
	// Update is called once per frame
	void Update () {
        if (target.position != targetLocal)
        {
            this.transform.position = local + (target.position - targetLocal) * scale;
        }
	}
}
