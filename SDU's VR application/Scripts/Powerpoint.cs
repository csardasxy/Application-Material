using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// In this script, we announced two functions related to the displayment of .ppt files.
/// Besides, we wrote a automatic script to convert .ppt files into pictures, and pack them into the project.
/// When the ppt files need to be changed, just repack the new picture set and import it.
/// </summary>

public class Powerpoint  MonoBehaviour {

	public int PptCount;

	private Image img;
	private Sprite[] ppts;

	private int _current;
	public int Current {
		set{
			if (ppts [value] == null) {
				ppts [value] = Resources.LoadSprite (ppts+value);
			}
			_current = value;
			img.sprite = ppts [value];
		}
		get{
			return _current;
		}
	}

	void Start(){
		ppts = new Sprite[PptCount];
		img = GetComponentImage ();
		Current = 0;
	}

	public void Next(){
		if (Current == ppts.Length - 1) {
			Current = 0;
		} else {
			Current++;
		}
	}

}