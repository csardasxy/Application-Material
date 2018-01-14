using UnityEngine;
using System.Collections;

/// <summary>
/// This controls the auto-displaying of the dialogue in the final scene.
/// </summary>

public class Words : MonoBehaviour {
    [SerializeField]
    string[] words;
    int next = 0;
    TextMesh text;
    public float timer = 0;
    GameObject target;
	// Use this for initialization

    void Start()
    {
        text = this.gameObject.transform.FindChild("text").gameObject.GetComponent<TextMesh>();
    }
    public void Reply(GameObject other)
    {
        if (words[next] == "")
            return;
        text.text = words[next++];
        if (next == 3 && this.gameObject.tag == "Player")
        {
            GetComponent<Aim_Shoot>().canShoot = true;
        }
        timer = 0;
        target = other;
        Invoke("WaitForReply", 2f);
    }

    public void SayNextWord()
    {
        text.text = words[next++];
        timer = 0;
    }

    public void WaitForReply()
    {
        target.GetComponent<Words>().Reply(this.gameObject);
    }

    void FixedUpdate()
    {
        if (this.gameObject.transform.localScale.x < 0)
            text.gameObject.transform.localScale = new Vector3(-1, 1, 1);
        else
            text.gameObject.transform.localScale = new Vector3(1, 1, 1);
        timer += Time.deltaTime;
        if(timer >= 3)
        {
            text.text = "";
        }
    }
}
