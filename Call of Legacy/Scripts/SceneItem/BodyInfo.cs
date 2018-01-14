using UnityEngine;
using System;

[Serializable]
public class BodyInfo {

    public static int IDCount = 1;

    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public float PositionZ { get; set; }
    public int Level { get; set; }
    public int Style { get; set; }//TODO ?
    public int ID { get; set; }

    public BodyInfo(Vector3 position,int level) {
        this.PositionX = position.x;
        this.PositionY = position.y;
        this.PositionZ = position.z;
        this.Level = level;
        this.ID = IDCount;
        IDCount++;
    }
}
