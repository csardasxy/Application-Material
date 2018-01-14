using UnityEngine;
using System.Collections;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

/// <summary>
/// This controls scenes' switch in the game
/// </summary>

public class SceneTrans : MonoBehaviour {

    public static bool isLoading = false;

    private GameController gc;
    private AsyncOperation ao;

    public loadScene slider;

	// Use this for initialization
	void Start () {
        gc = GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>();
        GameObject player = GameObject.FindGameObjectWithTag("Player");
        DanmakuSystem.idSet.Clear();
        DontDestroyOnLoad(gc.gameObject);
        if (player != null)
            DontDestroyOnLoad(player);
        StartCoroutine(loadScene());
        if (isLoading)
            Invoke("load", 1f);
        else
            gc.SceneLoadComplete = true;
    }
	
    private IEnumerator loadScene() {
        ao = SceneManager.LoadSceneAsync(gc.CurrentLevel);
        ao.allowSceneActivation = false;
        yield return ao;
    }

    private void load() {
        if (Save.loadCloud())
        {
            Debug.Log("loadCloud:" + true);
            gc.SceneLoadComplete = true;
        }
        else
        {
            Debug.Log("loadCloud:" + Save.loadLocal());
            gc.SceneLoadComplete = true;
        }
        isLoading = false;
    }

    private float curProgress = 0;

    // Update is called once per frame
    void Update () {
        if (ao == null)
            return;
        float progress = 0;
        if (ao.progress < 0.9f) {
            progress = ao.progress;
        } else {
            if (gc.SceneLoadComplete) {
                progress = 1;
            } else {
                progress = 0.9f;
            }
        }
        if (curProgress < progress) {
            curProgress += 0.01f;
        }
        slider.f = curProgress;
        if (curProgress >= 1) {
            ao.allowSceneActivation = true;
            gc.SceneLoadComplete = false;
        }
	}
}
