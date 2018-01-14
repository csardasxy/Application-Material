using UnityEngine;
using System.Collections;

public class BodyAction : MonoBehaviour {

    private MonumentSystem monumentSystem;
    private BodyInfo bodyInfo;

    // Use this for initialization
    void Start() {
        monumentSystem = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<MonumentSystem>();
    }

    void OnTriggerEnter(Collider collider) {
        if (collider.tag == "Player") {
            monumentSystem.inBodyRange = true;
            monumentSystem.body = gameObject;
        }
    }

    void OnTriggerExit(Collider collider) {
        if (collider.tag == "Player") {
            Debug.Log("exit");
            monumentSystem.inBodyRange = false;
            monumentSystem.body = null;
        }
    }

    public void setBodyInfo(BodyInfo info) {
        this.bodyInfo = info;
    }

    public BodyInfo getBodyInfo() {
        return bodyInfo;
    }
}
