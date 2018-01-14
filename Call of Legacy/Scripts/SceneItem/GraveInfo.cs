using UnityEngine;
using System.Collections;
using System;

[Serializable]
public class GraveInfo {

    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public float PositionZ { get; set; }
    public int Level { get; set; }
    public int Style { get; set; }

    public GraveInfo(Vector3 position, int level,int style) {
        this.PositionX = position.x;
        this.PositionY = position.y;
        this.PositionZ = position.z;
        this.Level = level;
        this.Style = style;
    }

}
