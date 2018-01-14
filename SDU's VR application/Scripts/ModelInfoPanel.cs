using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// This script is used to display a model prefab's text description attached.
/// </summary>


public class ModelInfoPanel : MonoBehaviour {

	private Text text;

	void Awake(){
		text = GetComponentInChildren<Text> ();
	}

	public void SetText(string text){
		this.text.text = text;
	}
}