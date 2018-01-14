using UnityEngine;
using System.Collections;

public class character : MonoBehaviour {

    public GameObject noposition;
    public GameObject showposition;
    public TP_Animator ta;
    public person per;
    bool show = false;
    Vector3 position;
    Vector3 sposition;

	// Use this for initialization
	void Start () {
        ta = GameObject.FindGameObjectWithTag("Player").GetComponent<TP_Animator>();
    }
	
	// Update is called once per frame
	void Update () {
        sposition = showposition.transform.localPosition;
        position = noposition.transform.localPosition;
        gameObject.transform.FindChild("HP").GetComponent<UILabel>().text = "生命值：" + per.HPNOW.ToString();
        gameObject.transform.FindChild("MP").GetComponent<UILabel>().text = "耐力值：" + per.MPNOW.ToString();
        gameObject.transform.FindChild("ATK").GetComponent<UILabel>().text = "攻击力：" + per.ATK.ToString();
        gameObject.transform.FindChild("DEF").GetComponent<UILabel>().text = "防御力：" + per.DEF.ToString();
        gameObject.transform.FindChild("DEX").GetComponent<UILabel>().text = "命中：" + per.DEX.ToString();
        gameObject.transform.FindChild("CRI").GetComponent<UILabel>().text = "暴击：" + per.CRI.ToString();
        gameObject.transform.FindChild("EVA").GetComponent<UILabel>().text = "闪避：" + per.EVA.ToString();
        gameObject.transform.FindChild("BLK").GetComponent<UILabel>().text = "格挡：" + per.BLK.ToString();
	}

    public void showperson()
    {
        if (show)
        {
            gameObject.transform.localPosition = position;
            show = false;
            ta.canAttack++;
        }
        else
        {
            gameObject.transform.localPosition = sposition;
            show = true;
            ta.canAttack--;
        }
    }
}
