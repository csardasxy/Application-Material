using UnityEngine;
using System.Collections.Generic;
using System.Collections;
using UnityEngine.SceneManagement;

public class MonumentSystem : MonoBehaviour {

    public static Stack<GraveInfo> Graves { get; set; }
    public static List<BodyInfo> Bodys { get; set; }
    public static Vector3 DefaultPosition = new Vector3(134.312f, -6f, 36f);

    public bool inBodyRange = false;

    public GameObject[] monumentPrefabs;
    public GameObject BodyPrefab;

    public GameObject body;

    private GameObject player;
    private GameController gc;

	// Use this for initialization
	void Start () {
        player = GameObject.FindGameObjectWithTag("Player");
        gc = GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>();
	}

    private bool firstCallDead = true;
    private float time = 0;

	// Update is called once per frame
	void Update () {
        if (TP_Animator.Instance.IsDead) {
            if (firstCallDead) {
                time = Time.time;
                firstCallDead = false;
            }
            if (player.GetComponent<Rigidbody>().velocity.Equals(Vector3.zero)&&Time.time-time>=3.0f) {
                firstCallDead = true;
                BodyInfo info = new BodyInfo(player.transform.position, gc.CurrentLevel);
                if (Bodys != null)
                    Bodys.Add(info);
                else {
                    Bodys = new List<BodyInfo>();
                    Bodys.Add(info);
                }

                if (Graves == null || Graves.Count == 0) {
                    Save.PlayerPosition = DefaultPosition;
                    Debug.Log(DefaultPosition);
                    gc.CurrentLevel = 2;
                } else {
                    gc.CurrentLevel = Graves.Peek().Level;
                    Save.PlayerPosition = new Vector3(Graves.Peek().PositionX, Graves.Peek().PositionY, Graves.Peek().PositionZ);
                }

                TP_Animator.Instance.Reset();
                
                SceneManager.LoadScene("loading");
            }
        }
    }

    public void Build(int style) {
        if (!inBodyRange)
            return;
        if (body != null) {
            Vector3 pos = body.transform.position;
            if (Bodys != null) {
                int id = body.GetComponent<BodyAction>().getBodyInfo().ID;
                for (int i = 0; i < Bodys.Count; i++) {
                    if (Bodys[i].ID == id) {
                        Bodys.RemoveAt(i);
                    }
                }
            }
            Destroy(body);
            GameObject m = Instantiate(monumentPrefabs[style], new Vector3(pos.x, pos.y, pos.z), Quaternion.identity) as GameObject;
            if (Graves != null) {
                Graves.Push(new GraveInfo(m.transform.position, gc.CurrentLevel, style));
            } else {
                Graves = new Stack<GraveInfo>();
                Graves.Push(new GraveInfo(m.transform.position, gc.CurrentLevel, style));
            }
        }
    }
}
