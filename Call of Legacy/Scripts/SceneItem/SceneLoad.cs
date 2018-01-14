using UnityEngine;
using System.Collections;

public class SceneLoad : MonoBehaviour {

    private GameController gc;

    // Use this for initialization
    void Start () {
        gc = GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>();
        StartCoroutine(gc.loadGameObjects());
    }

}
