using UnityEngine;
using System.Collections;

/// <summary>
/// At the end of the game, there is a short music vedio that shows the great loss during the World War II.
/// And this vedio is played as a movieTexture (QuickTime required).
/// </summary>

public class MoviePlayer : MonoBehaviour {

    public MovieTexture movTexture;

    void Awake()
    {
        GetComponent<Renderer>().material.mainTexture = movTexture;
        movTexture.loop = false;
        movTexture.Play();
        GetComponent<AudioSource>().Play();
    }


}
