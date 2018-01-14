using UnityEngine;
using System.Collections;

public class MonumentAction : MonoBehaviour {

    private MonumentSystem monumentSystem;
    private GraveInfo graveInfo;
    private person pe;

    // Use this for initialization
    void Start() {
        monumentSystem = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<MonumentSystem>();
        pe = GameObject.FindGameObjectWithTag("Player").GetComponent<person>();
    }

    private float timeNow = 0;

    void OnTriggerStay(Collider other) {
        if (other.tag == "Player") {
            if(Time.time - timeNow > 0.5f)
            {
                pe.setHPNOW(5);
                timeNow = Time.time;
            }
            if (Input.GetKeyDown("e"))
            {
                if (Save.saveCloud())
                {
                    Debug.Log("saveCloud:" + true);
                }
                else
                {
                    Debug.Log("saveLocal:" + Save.saveLocal());
                }
            }
            Debug.Log("stay");
        }
    }

    public void setGraveInfo(GraveInfo info) {
        this.graveInfo = info;
    }

    public GraveInfo getGraveInfo() {
        return graveInfo;
    }
}
