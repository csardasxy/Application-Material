using UnityEngine;
using System.Collections;

public class HUD : MonoBehaviour
{
    public TP_Animator ta;
    // Use this for initialization
    void Start()
    {
        ta = GameObject.FindGameObjectWithTag("Player").GetComponent<TP_Animator>();

    }

    void OnMouseEnter()
    {
        ta.canAttack--;
    }

    void OnMouseExit()
    {
        ta.canAttack++;
    }
}