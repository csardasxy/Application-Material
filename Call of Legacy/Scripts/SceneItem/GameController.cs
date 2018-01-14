using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>
/// This controls the initialization os game's scene
/// </summary>

public class GameController : MonoBehaviour {

    private Cloud cloud;
    private GameObject player;
    private DanmakuSystem danmakuSystem;
    private MonumentSystem monumentSystem;

    public int CurrentLevel = 1;
    public bool SceneLoadComplete = false;

    // Use this for initialization
    void Start() {
        player = GameObject.FindGameObjectWithTag("Player");
        cloud = GetComponent<Cloud>();
        //danmakuSystem = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<DanmakuSystem>();
        //monumentSystem = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<MonumentSystem>();
    }

    // Update is called once per frame
    void Update() {

    }

    public IEnumerator loadGameObjects() {
        player = GameObject.FindGameObjectWithTag("Player");
        cloud = GetComponent<Cloud>();
        danmakuSystem = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<DanmakuSystem>();
        monumentSystem = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<MonumentSystem>();

        yield return new WaitForSeconds(1);
        player.transform.position = Save.PlayerPosition;

        if (MonumentSystem.Graves!=null)
            foreach (GraveInfo g in MonumentSystem.Graves) {
                if (g.Level == CurrentLevel) {
                    Instantiate(monumentSystem.monumentPrefabs[g.Style], new Vector3(g.PositionX, g.PositionY, g.PositionZ), Quaternion.identity);
                }
                yield return 0;
            }
        if(MonumentSystem.Bodys!=null)
            foreach (BodyInfo b in MonumentSystem.Bodys) {
                if (b.Level == CurrentLevel) {
                    GameObject body = Instantiate(monumentSystem.BodyPrefab, new Vector3(b.PositionX, b.PositionY, b.PositionZ), Quaternion.identity) as GameObject;
                    body.AddComponent<BodyAction>().setBodyInfo(b);
                }
                yield return 0;
            }
    }


}
