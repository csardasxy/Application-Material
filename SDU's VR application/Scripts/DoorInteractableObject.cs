using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using VRTK;

/// <summary>
/// This script can show (hide) objects in a room when player enter (leave) this room.
/// We adopt this script in order to optimize this VR application's fps.
/// </summary>

[RequireComponent(typeof(DoorDestinationMarker))]
public class DoorInteractableObject : VRTK_InteractableObject {

	[Header("Door Interactable Object")]

	[Tooltip("传送相关的房间")]
	public GameObject Room;
	[Tooltip("大厅的大模型")]
	public GameObject Model;
	[Tooltip("这个门是返回大厅的门吗")]
	public bool IsOut;

	private DoorDestinationMarker marker;
	private Transform controller;

	void Awake(){
		if(Room == null)
			Debug.LogError("["+name+"] Room没有设置！");
		if(Model == null)
			Debug.LogError("["+name+"] Model没有设置！");
	}

	void Start(){
		marker = GetComponent<DoorDestinationMarker> ();
		controller = VRTK_DeviceFinder.DeviceTransform (VRTK_DeviceFinder.Devices.Right_Controller);
	}

	public override void StartUsing (GameObject currentUsingObject) {
		base.StartUsing (currentUsingObject);

		if ((controller.position - transform.position).magnitude < 0.5) {
			if (!IsOut) {
				Room.SetActive (true);
				Model.SetActive (false);
			}
			marker.Teleport (currentUsingObject);
			if (IsOut) {
				Room.SetActive (false);
				Model.SetActive (true);
			}
		}
	}

	
	//override the functions which are triggered when the controller start or stop touching this door object.
	public override void StartTouching (GameObject currentTouchingObject) {
		base.StartTouching (currentTouchingObject);

		if ((controller.position - transform.position).magnitude < 0.5) {
			VRTK_ControllerActions action = currentTouchingObject.GetComponent<VRTK_ControllerActions> ();
			action.ToggleHighlightGrip (true, Color.yellow);
			action.SetControllerOpacity (0.5f);
		}
	}

	public override void StopTouching (GameObject previousTouchingObject) {
		base.StopTouching (previousTouchingObject);

		VRTK_ControllerActions action = previousTouchingObject.GetComponent<VRTK_ControllerActions> ();
		action.ToggleHighlightGrip (false);
		action.SetControllerOpacity (1f);
	}

}