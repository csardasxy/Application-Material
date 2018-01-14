using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using VRTK;

/// <summary>
/// This script enables players to teleport between two positions.
/// </summary>

public class DoorDestinationMarker : VRTK_DestinationMarker {
	
	private Transform destination;

	void Awake(){
        //Find the target position.
		destination = transform.GetChild (0);
		if(destination == null)
			Debug.LogError("["+name+"] 没有Destination子物体！");
	}

    //When the controller triggers the collider attached to the gate, this function will be invoked.
	public void Teleport(GameObject controller){
		var distance = Vector3.Distance(transform.position, destination.position);
		var controllerIndex = VRTK_DeviceFinder.GetControllerIndex(controller.gameObject);
		OnDestinationMarkerSet(SetDestinationMarkerEvent(distance, destination, new RaycastHit(), destination.position, controllerIndex));
	}

}